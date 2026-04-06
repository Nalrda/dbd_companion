// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get settings => 'USTAWIENIA';

  @override
  String get colorTheme => 'MOTYW KOLORYSTYCZNY';

  @override
  String get signInWithGoogle => 'ZALOGUJ PRZEZ GOOGLE';

  @override
  String get signOut => 'WYLOGUJ SIĘ';

  @override
  String get perks => 'Perki';

  @override
  String get tabBuilds => 'BUILDY';

  @override
  String get tabGroup => 'GRUPA';

  @override
  String get tabRandom => 'LOSOWE';

  @override
  String get tabMatches => 'MECZE';

  @override
  String get tabMaps => 'MAPY';

  @override
  String get tabMore => 'WIĘCEJ';

  @override
  String get searchHint => 'Szukaj po nazwie, postaci, tagu...';

  @override
  String get noResults => 'Brak wyników';

  @override
  String noPerkFound(String search) {
    return 'Nie znaleziono perka dla zapytania: \"$search\"';
  }

  @override
  String get survivor => 'Ocalały';

  @override
  String get killer => 'Zabójca';

  @override
  String get language => 'JĘZYK APLIKACJI';

  @override
  String get languageTitle => 'JĘZYK';

  @override
  String get english => 'Angielski';

  @override
  String get polish => 'Polski';

  @override
  String perksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perka',
      many: '$count perków',
      few: '$count perki',
      one: '1 perk',
    );
    return '$_temp0';
  }

  @override
  String get guestModeDesc => 'Tryb gościa — dane nie są zapisywane w chmurze';

  @override
  String get signIn => 'Zaloguj się';

  @override
  String get myBuilds => 'Moje Buildy';

  @override
  String get createBuild => 'Stwórz Build';

  @override
  String get groupPlannerTitle => 'Planer Grupy';

  @override
  String get randomizerTitle => 'Losowanie';

  @override
  String get matchesTitle => 'Mecze';

  @override
  String get mapsTitle => 'Mapy';

  @override
  String get noBuildsYet => 'Brak buildów';

  @override
  String get createFirstSurvivorBuild => 'Stwórz swój pierwszy build Ocalałego';

  @override
  String get createFirstKillerBuild => 'Stwórz swój pierwszy build Zabójcy';

  @override
  String get noGroupPlansYet => 'Brak planów grupy';

  @override
  String get planBuildsForSquad =>
      'Zaplanuj buildy dla swojej 4-osobowej grupy';

  @override
  String get createGroupPlan => 'Stwórz Plan Grupy';

  @override
  String get yourBuild => 'TWÓJ BUILD';

  @override
  String perkNumber(int index) {
    return 'Perk $index';
  }

  @override
  String get rollPerks => 'Wylosuj Perki';

  @override
  String get saveAsBuild => 'Zapisz jako Build';

  @override
  String get noMatchesRecorded => 'Brak zarejestrowanych meczów';

  @override
  String get trackSurvivorGames => 'Śledź swoje mecze Ocalałym tutaj';

  @override
  String get trackKillerGames => 'Śledź swoje mecze Zabójcą tutaj';

  @override
  String get addMatch => 'Dodaj Mecz';
}
