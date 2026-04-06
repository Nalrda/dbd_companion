import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/killer.dart';
import '../../../core/models/perk.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/repositories/killer_repository.dart';
import '../../../core/repositories/perk_repository.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _todayKey() {
  final now = DateTime.now();
  final y = now.year.toString();
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

T _dailyItem<T>(List<T> items) {
  final now = DateTime.now();
  final seed = now.year * 10000 + now.month * 100 + now.day;
  return items[Random(seed).nextInt(items.length)];
}

// ─── Perk Game ────────────────────────────────────────────────────────────────

class PerkGameState {
  final Perk? targetPerk;
  final List<Perk> wrongGuesses;
  final bool isWon;
  final String date;

  const PerkGameState({
    this.targetPerk,
    this.wrongGuesses = const [],
    this.isWon = false,
    this.date = '',
  });

  // Start: sigma 20, each wrong guess -3, floor at 0 → fully revealed after 7 wrongs
  double get blurSigma => max(0.0, 20.0 - wrongGuesses.length * 3.0);

  PerkGameState copyWith({
    Perk? targetPerk,
    List<Perk>? wrongGuesses,
    bool? isWon,
    String? date,
  }) =>
      PerkGameState(
        targetPerk: targetPerk ?? this.targetPerk,
        wrongGuesses: wrongGuesses ?? this.wrongGuesses,
        isWon: isWon ?? this.isWon,
        date: date ?? this.date,
      );

  Map<String, dynamic> toJson() => {
        'targetPerkId': targetPerk?.id,
        'wrongGuessIds': wrongGuesses.map((p) => p.id).toList(),
        'isWon': isWon,
        'date': date,
      };

  static PerkGameState fromJson(Map<String, dynamic> json, List<Perk> allPerks) {
    final targetId = json['targetPerkId'] as String?;
    final wrongIds = List<String>.from(json['wrongGuessIds'] as List? ?? []);
    final target = targetId == null
        ? null
        : allPerks.firstWhere((p) => p.id == targetId, orElse: () => allPerks.first);
    final wrong = allPerks.where((p) => wrongIds.contains(p.id)).toList();
    return PerkGameState(
      targetPerk: target,
      wrongGuesses: wrong,
      isWon: json['isWon'] as bool? ?? false,
      date: json['date'] as String? ?? '',
    );
  }
}

class PerkGameNotifier extends StateNotifier<AsyncValue<PerkGameState>> {
  final SharedPreferences _prefs;

  PerkGameNotifier(this._prefs) : super(const AsyncValue.loading()) {
    _init();
  }

  static const _prefix = 'dbdle_perk_';

  Future<void> _init() async {
    final allPerks = await PerkRepository.instance.getAllPerks();
    final today = _todayKey();
    final saved = _prefs.getString('$_prefix$today');

    if (saved != null) {
      try {
        final parsed = PerkGameState.fromJson(
          jsonDecode(saved) as Map<String, dynamic>,
          allPerks,
        );
        state = AsyncValue.data(parsed);
        return;
      } catch (_) {}
    }

    final target = _dailyItem(allPerks);
    final fresh = PerkGameState(targetPerk: target, date: today);
    state = AsyncValue.data(fresh);
    await _save(fresh);
  }

  Future<void> guess(Perk perk) async {
    final current = state.valueOrNull;
    if (current == null || current.isWon) return;
    if (current.targetPerk == null) return;

    final alreadyGuessed = current.wrongGuesses.any((p) => p.id == perk.id) ||
        current.targetPerk!.id == perk.id;
    if (alreadyGuessed) return;

    if (perk.id == current.targetPerk!.id) {
      final next = current.copyWith(isWon: true);
      state = AsyncValue.data(next);
      await _save(next);
    } else {
      final next = current.copyWith(
        wrongGuesses: [...current.wrongGuesses, perk],
      );
      state = AsyncValue.data(next);
      await _save(next);
    }
  }

  Future<void> _save(PerkGameState s) async {
    await _prefs.setString('$_prefix${s.date}', jsonEncode(s.toJson()));
  }
}

final perkGameProvider =
    StateNotifierProvider<PerkGameNotifier, AsyncValue<PerkGameState>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PerkGameNotifier(prefs);
});

// ─── Killer Game ──────────────────────────────────────────────────────────────

enum ComparisonResult { correct, higher, lower }

class KillerGuess {
  final Killer killer;
  final bool heightMatch;
  final ComparisonResult speedResult;
  final ComparisonResult terrorResult;

  const KillerGuess({
    required this.killer,
    required this.heightMatch,
    required this.speedResult,
    required this.terrorResult,
  });

  static KillerGuess compare(Killer guessed, Killer target) {
    ComparisonResult cmpDouble(double a, double b) {
      if ((a - b).abs() < 0.001) return ComparisonResult.correct;
      return a < b ? ComparisonResult.lower : ComparisonResult.higher;
    }

    ComparisonResult cmpInt(int a, int b) {
      if (a == b) return ComparisonResult.correct;
      return a < b ? ComparisonResult.lower : ComparisonResult.higher;
    }

    return KillerGuess(
      killer: guessed,
      heightMatch: guessed.height == target.height,
      speedResult: cmpDouble(guessed.movementSpeed, target.movementSpeed),
      terrorResult: cmpInt(guessed.terrorRadius, target.terrorRadius),
    );
  }
}

class KillerGameState {
  final Killer? targetKiller;
  final List<KillerGuess> guesses;
  final bool isWon;
  final String date;

  const KillerGameState({
    this.targetKiller,
    this.guesses = const [],
    this.isWon = false,
    this.date = '',
  });

  KillerGameState copyWith({
    Killer? targetKiller,
    List<KillerGuess>? guesses,
    bool? isWon,
    String? date,
  }) =>
      KillerGameState(
        targetKiller: targetKiller ?? this.targetKiller,
        guesses: guesses ?? this.guesses,
        isWon: isWon ?? this.isWon,
        date: date ?? this.date,
      );

  Map<String, dynamic> toJson() => {
        'targetKillerId': targetKiller?.id,
        'guessIds': guesses.map((g) => g.killer.id).toList(),
        'isWon': isWon,
        'date': date,
      };

  static KillerGameState fromJson(
    Map<String, dynamic> json,
    List<Killer> allKillers,
    Killer target,
  ) {
    final guessIds = List<String>.from(json['guessIds'] as List? ?? []);
    final guesses = guessIds
        .map((id) {
          try {
            final k = allKillers.firstWhere((k) => k.id == id);
            return KillerGuess.compare(k, target);
          } catch (_) {
            return null;
          }
        })
        .whereType<KillerGuess>()
        .toList();
    return KillerGameState(
      targetKiller: target,
      guesses: guesses,
      isWon: json['isWon'] as bool? ?? false,
      date: json['date'] as String? ?? '',
    );
  }
}

class KillerGameNotifier extends StateNotifier<AsyncValue<KillerGameState>> {
  final SharedPreferences _prefs;

  KillerGameNotifier(this._prefs) : super(const AsyncValue.loading()) {
    _init();
  }

  static const _prefix = 'dbdle_killer_';

  Future<void> _init() async {
    final allKillers = await KillerRepository.instance.getAll();
    final today = _todayKey();
    // Use a different seed offset for killers so it doesn't pick the same index as perks
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day + 1337;
    final target = allKillers[Random(seed).nextInt(allKillers.length)];

    final saved = _prefs.getString('$_prefix$today');
    if (saved != null) {
      try {
        final parsed = KillerGameState.fromJson(
          jsonDecode(saved) as Map<String, dynamic>,
          allKillers,
          target,
        );
        state = AsyncValue.data(parsed);
        return;
      } catch (_) {}
    }

    final fresh = KillerGameState(targetKiller: target, date: today);
    state = AsyncValue.data(fresh);
    await _save(fresh);
  }

  Future<void> guess(Killer killer) async {
    final current = state.valueOrNull;
    if (current == null || current.isWon || current.targetKiller == null) return;

    final alreadyGuessed = current.guesses.any((g) => g.killer.id == killer.id);
    if (alreadyGuessed) return;

    final result = KillerGuess.compare(killer, current.targetKiller!);
    final won = killer.id == current.targetKiller!.id;

    final next = current.copyWith(
      guesses: [...current.guesses, result],
      isWon: won,
    );
    state = AsyncValue.data(next);
    await _save(next);
  }

  Future<void> _save(KillerGameState s) async {
    await _prefs.setString('$_prefix${s.date}', jsonEncode(s.toJson()));
  }
}

final killerGameProvider =
    StateNotifierProvider<KillerGameNotifier, AsyncValue<KillerGameState>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return KillerGameNotifier(prefs);
});
