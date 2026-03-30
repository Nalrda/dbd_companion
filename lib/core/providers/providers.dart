import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/build.dart';
import '../models/group_plan.dart';
import '../models/item.dart';
import '../models/killer.dart';
import '../models/map_callout.dart';
import '../models/match_record.dart';
import '../models/offering.dart';
import '../models/perk.dart';
import '../repositories/build_repository.dart';
import '../repositories/group_plan_repository.dart';
import '../repositories/item_repository.dart';
import '../repositories/killer_repository.dart';
import '../repositories/map_repository.dart';
import '../repositories/match_repository.dart';
import '../repositories/offering_repository.dart';
import '../repositories/perk_repository.dart';

// ─── Perk providers ───────────────────────────────────────────────────────────

final allPerksProvider = FutureProvider<List<Perk>>((ref) async {
  return PerkRepository.instance.getAllPerks();
});

final survivorPerksProvider = FutureProvider<List<Perk>>((ref) async {
  return PerkRepository.instance.getSurvivorPerks();
});

final killerPerksProvider = FutureProvider<List<Perk>>((ref) async {
  return PerkRepository.instance.getKillerPerks();
});

// ─── Build providers ──────────────────────────────────────────────────────────

final buildsProvider =
    AsyncNotifierProvider<BuildsNotifier, List<Build>>(BuildsNotifier.new);

class BuildsNotifier extends AsyncNotifier<List<Build>> {
  @override
  Future<List<Build>> build() async {
    return BuildRepository.instance.getAllBuilds();
  }

  Future<Build> create({
    required String name,
    required bool isSurvivor,
    List<String>? perkIds,
    String? notes,
    List<String>? tags,
  }) async {
    final newBuild = await BuildRepository.instance.createBuild(
      name: name,
      isSurvivor: isSurvivor,
      perkIds: perkIds,
      notes: notes,
      tags: tags,
    );
    ref.invalidateSelf();
    return newBuild;
  }

  Future<void> save(Build build) async {
    await BuildRepository.instance.saveBuild(build);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await BuildRepository.instance.deleteBuild(id);
    ref.invalidateSelf();
  }

  Future<void> toggleFavorite(String id) async {
    final builds = state.value ?? [];
    final build = builds.firstWhere((b) => b.id == id);
    await BuildRepository.instance.saveBuild(
      build.copyWith(isFavorite: !build.isFavorite),
    );
    ref.invalidateSelf();
  }
}

// ─── Randomizer state ─────────────────────────────────────────────────────────

class RandomizerState {
  final bool isSurvivor;
  final List<Perk> selectedPerks;
  final bool isRolling;

  const RandomizerState({
    this.isSurvivor = true,
    this.selectedPerks = const [],
    this.isRolling = false,
  });

  RandomizerState copyWith({
    bool? isSurvivor,
    List<Perk>? selectedPerks,
    bool? isRolling,
  }) {
    return RandomizerState(
      isSurvivor: isSurvivor ?? this.isSurvivor,
      selectedPerks: selectedPerks ?? this.selectedPerks,
      isRolling: isRolling ?? this.isRolling,
    );
  }
}

final randomizerProvider =
    NotifierProvider<RandomizerNotifier, RandomizerState>(
        RandomizerNotifier.new);

class RandomizerNotifier extends Notifier<RandomizerState> {
  @override
  RandomizerState build() => const RandomizerState();

  void toggleRole() {
    state = state.copyWith(
      isSurvivor: !state.isSurvivor,
      selectedPerks: [],
    );
  }

  Future<void> roll() async {
    state = state.copyWith(isRolling: true);

    await Future.delayed(const Duration(milliseconds: 600));

    final perks = state.isSurvivor
        ? await PerkRepository.instance.getSurvivorPerks()
        : await PerkRepository.instance.getKillerPerks();

    perks.shuffle();
    final picked = perks.take(4).toList();

    state = state.copyWith(selectedPerks: picked, isRolling: false);
  }

  void setRole(bool isSurvivor) {
    state = state.copyWith(isSurvivor: isSurvivor, selectedPerks: []);
  }
}

// ─── Item providers ───────────────────────────────────────────────────────────

final survivorItemsProvider = FutureProvider<List<Item>>((ref) async {
  return ItemRepository.instance.getSurvivorItems();
});

// ─── Offering providers ───────────────────────────────────────────────────────

final survivorOfferingsProvider = FutureProvider<List<Offering>>((ref) async {
  return OfferingRepository.instance.getForRole(isSurvivor: true);
});

final killerOfferingsProvider = FutureProvider<List<Offering>>((ref) async {
  return OfferingRepository.instance.getForRole(isSurvivor: false);
});

// ─── Map Callout providers ────────────────────────────────────────────────────

final mapRealmsProvider = FutureProvider<List<MapRealm>>((ref) async {
  return MapRepository().getRealms();
});

// ─── Killer providers ─────────────────────────────────────────────────────────

final killersProvider = FutureProvider<List<Killer>>((ref) async {
  return KillerRepository.instance.getAll();
});

// ─── Match providers ──────────────────────────────────────────────────────────

final matchesProvider =
    AsyncNotifierProvider<MatchesNotifier, List<MatchRecord>>(MatchesNotifier.new);

class MatchesNotifier extends AsyncNotifier<List<MatchRecord>> {
  @override
  Future<List<MatchRecord>> build() async {
    return MatchRepository.instance.getAll();
  }

  Future<void> add({
    required bool isSurvivor,
    required String outcome,
    String? characterName,
    String? mapName,
    List<String>? perkIds,
    String? notes,
  }) async {
    await MatchRepository.instance.create(
      isSurvivor: isSurvivor,
      outcome: outcome,
      characterName: characterName,
      mapName: mapName,
      perkIds: perkIds,
      notes: notes,
    );
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await MatchRepository.instance.delete(id);
    ref.invalidateSelf();
  }
}

// ─── Group Plan providers ─────────────────────────────────────────────────────

final groupPlansProvider =
    AsyncNotifierProvider<GroupPlansNotifier, List<GroupPlan>>(GroupPlansNotifier.new);

class GroupPlansNotifier extends AsyncNotifier<List<GroupPlan>> {
  @override
  Future<List<GroupPlan>> build() async {
    return GroupPlanRepository.instance.getAll();
  }

  Future<GroupPlan> create({required String name}) async {
    final plan = await GroupPlanRepository.instance.create(name: name);
    ref.invalidateSelf();
    return plan;
  }

  Future<void> save(GroupPlan plan) async {
    await GroupPlanRepository.instance.save(plan);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await GroupPlanRepository.instance.delete(id);
    ref.invalidateSelf();
  }
}
