// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'SETTINGS';

  @override
  String get colorTheme => 'COLOR THEME';

  @override
  String get signInWithGoogle => 'SIGN IN WITH GOOGLE';

  @override
  String get signOut => 'SIGN OUT';

  @override
  String get perks => 'Perks';

  @override
  String get tabBuilds => 'BUILDS';

  @override
  String get tabGroup => 'GROUP';

  @override
  String get tabRandom => 'RANDOM';

  @override
  String get tabMatches => 'MATCHES';

  @override
  String get tabMaps => 'MAPS';

  @override
  String get tabMore => 'MORE';

  @override
  String get searchHint => 'Search by name, character, tag...';

  @override
  String get noResults => 'No results';

  @override
  String noPerkFound(String search) {
    return 'No perk found for \"$search\"';
  }

  @override
  String get survivor => 'Survivor';

  @override
  String get killer => 'Killer';

  @override
  String get language => 'SYSTEM LANGUAGE';

  @override
  String get languageTitle => 'APLIKACJA';

  @override
  String get english => 'English';

  @override
  String get polish => 'Polish';

  @override
  String perksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perks',
      one: '1 perk',
    );
    return '$_temp0';
  }

  @override
  String get guestModeDesc => 'Guest mode — your data is not saved online';

  @override
  String get signIn => 'Sign In';

  @override
  String get myBuilds => 'My Builds';

  @override
  String get createBuild => 'Create Build';

  @override
  String get groupPlannerTitle => 'Group Planner';

  @override
  String get randomizerTitle => 'Randomizer';

  @override
  String get matchesTitle => 'Matches';

  @override
  String get mapsTitle => 'Maps';

  @override
  String get noBuildsYet => 'No builds yet';

  @override
  String get createFirstSurvivorBuild => 'Create your first survivor build';

  @override
  String get createFirstKillerBuild => 'Create your first killer build';

  @override
  String get noGroupPlansYet => 'No group plans yet';

  @override
  String get planBuildsForSquad => 'Plan builds for your full 4-survivor squad';

  @override
  String get createGroupPlan => 'Create Group Plan';

  @override
  String get yourBuild => 'YOUR BUILD';

  @override
  String perkNumber(int index) {
    return 'Perk $index';
  }

  @override
  String get rollPerks => 'Roll Perks';

  @override
  String get saveAsBuild => 'Save as Build';

  @override
  String get noMatchesRecorded => 'No matches recorded';

  @override
  String get trackSurvivorGames => 'Track your survivor games here';

  @override
  String get trackKillerGames => 'Track your killer games here';

  @override
  String get addMatch => 'Add Match';
}
