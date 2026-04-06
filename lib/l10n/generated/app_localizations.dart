import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl')
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settings;

  /// No description provided for @colorTheme.
  ///
  /// In en, this message translates to:
  /// **'COLOR THEME'**
  String get colorTheme;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN WITH GOOGLE'**
  String get signInWithGoogle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'SIGN OUT'**
  String get signOut;

  /// No description provided for @perks.
  ///
  /// In en, this message translates to:
  /// **'Perks'**
  String get perks;

  /// No description provided for @tabBuilds.
  ///
  /// In en, this message translates to:
  /// **'BUILDS'**
  String get tabBuilds;

  /// No description provided for @tabGroup.
  ///
  /// In en, this message translates to:
  /// **'GROUP'**
  String get tabGroup;

  /// No description provided for @tabRandom.
  ///
  /// In en, this message translates to:
  /// **'RANDOM'**
  String get tabRandom;

  /// No description provided for @tabMatches.
  ///
  /// In en, this message translates to:
  /// **'MATCHES'**
  String get tabMatches;

  /// No description provided for @tabMaps.
  ///
  /// In en, this message translates to:
  /// **'MAPS'**
  String get tabMaps;

  /// No description provided for @tabMore.
  ///
  /// In en, this message translates to:
  /// **'MORE'**
  String get tabMore;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, character, tag...'**
  String get searchHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @noPerkFound.
  ///
  /// In en, this message translates to:
  /// **'No perk found for \"{search}\"'**
  String noPerkFound(String search);

  /// No description provided for @survivor.
  ///
  /// In en, this message translates to:
  /// **'Survivor'**
  String get survivor;

  /// No description provided for @killer.
  ///
  /// In en, this message translates to:
  /// **'Killer'**
  String get killer;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM LANGUAGE'**
  String get language;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'APLIKACJA'**
  String get languageTitle;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @polish.
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get polish;

  /// No description provided for @perksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 perk} other {{count} perks}}'**
  String perksCount(int count);

  /// No description provided for @guestModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Guest mode — your data is not saved online'**
  String get guestModeDesc;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @myBuilds.
  ///
  /// In en, this message translates to:
  /// **'My Builds'**
  String get myBuilds;

  /// No description provided for @createBuild.
  ///
  /// In en, this message translates to:
  /// **'Create Build'**
  String get createBuild;

  /// No description provided for @groupPlannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Planner'**
  String get groupPlannerTitle;

  /// No description provided for @randomizerTitle.
  ///
  /// In en, this message translates to:
  /// **'Randomizer'**
  String get randomizerTitle;

  /// No description provided for @matchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matchesTitle;

  /// No description provided for @mapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Maps'**
  String get mapsTitle;

  /// No description provided for @noBuildsYet.
  ///
  /// In en, this message translates to:
  /// **'No builds yet'**
  String get noBuildsYet;

  /// No description provided for @createFirstSurvivorBuild.
  ///
  /// In en, this message translates to:
  /// **'Create your first survivor build'**
  String get createFirstSurvivorBuild;

  /// No description provided for @createFirstKillerBuild.
  ///
  /// In en, this message translates to:
  /// **'Create your first killer build'**
  String get createFirstKillerBuild;

  /// No description provided for @noGroupPlansYet.
  ///
  /// In en, this message translates to:
  /// **'No group plans yet'**
  String get noGroupPlansYet;

  /// No description provided for @planBuildsForSquad.
  ///
  /// In en, this message translates to:
  /// **'Plan builds for your full 4-survivor squad'**
  String get planBuildsForSquad;

  /// No description provided for @createGroupPlan.
  ///
  /// In en, this message translates to:
  /// **'Create Group Plan'**
  String get createGroupPlan;

  /// No description provided for @yourBuild.
  ///
  /// In en, this message translates to:
  /// **'YOUR BUILD'**
  String get yourBuild;

  /// No description provided for @perkNumber.
  ///
  /// In en, this message translates to:
  /// **'Perk {index}'**
  String perkNumber(int index);

  /// No description provided for @rollPerks.
  ///
  /// In en, this message translates to:
  /// **'Roll Perks'**
  String get rollPerks;

  /// No description provided for @saveAsBuild.
  ///
  /// In en, this message translates to:
  /// **'Save as Build'**
  String get saveAsBuild;

  /// No description provided for @noMatchesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No matches recorded'**
  String get noMatchesRecorded;

  /// No description provided for @trackSurvivorGames.
  ///
  /// In en, this message translates to:
  /// **'Track your survivor games here'**
  String get trackSurvivorGames;

  /// No description provided for @trackKillerGames.
  ///
  /// In en, this message translates to:
  /// **'Track your killer games here'**
  String get trackKillerGames;

  /// No description provided for @addMatch.
  ///
  /// In en, this message translates to:
  /// **'Add Match'**
  String get addMatch;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
