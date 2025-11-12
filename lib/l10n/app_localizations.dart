import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Territory Run'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get run;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @startRun.
  ///
  /// In en, this message translates to:
  /// **'Start Run'**
  String get startRun;

  /// No description provided for @pauseRun.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseRun;

  /// No description provided for @resumeRun.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeRun;

  /// No description provided for @stopRun.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopRun;

  /// No description provided for @saveRun.
  ///
  /// In en, this message translates to:
  /// **'Save Run'**
  String get saveRun;

  /// No description provided for @discardRun.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardRun;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @pace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get pace;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @elevation.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get elevation;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @mi.
  ///
  /// In en, this message translates to:
  /// **'mi'**
  String get mi;

  /// No description provided for @meters.
  ///
  /// In en, this message translates to:
  /// **'meters'**
  String get meters;

  /// No description provided for @feet.
  ///
  /// In en, this message translates to:
  /// **'feet'**
  String get feet;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @noRunsYet.
  ///
  /// In en, this message translates to:
  /// **'No runs yet'**
  String get noRunsYet;

  /// No description provided for @startFirstRun.
  ///
  /// In en, this message translates to:
  /// **'Start your first run!'**
  String get startFirstRun;

  /// No description provided for @adjustmentStep.
  ///
  /// In en, this message translates to:
  /// **'Adjustment step'**
  String get adjustmentStep;

  /// No description provided for @settingsApp.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get settingsApp;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsUnits;

  /// No description provided for @settingsGps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get settingsGps;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get settingsPrivacy;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @unitsMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric System'**
  String get unitsMetric;

  /// No description provided for @unitsImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial System'**
  String get unitsImperial;

  /// No description provided for @gpsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get gpsAccuracy;

  /// No description provided for @gpsAccuracyLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get gpsAccuracyLow;

  /// No description provided for @gpsAccuracyBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get gpsAccuracyBalanced;

  /// No description provided for @gpsAccuracyHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get gpsAccuracyHigh;

  /// No description provided for @autoPause.
  ///
  /// In en, this message translates to:
  /// **'Auto Pause'**
  String get autoPause;

  /// No description provided for @autoPauseDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically pause when you stop'**
  String get autoPauseDescription;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get notificationsEnabled;

  /// No description provided for @notificationsRunReminders.
  ///
  /// In en, this message translates to:
  /// **'Run reminders'**
  String get notificationsRunReminders;

  /// No description provided for @notificationsAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements and levels'**
  String get notificationsAchievements;

  /// No description provided for @notificationsWeeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly report'**
  String get notificationsWeeklyReport;

  /// No description provided for @privacyPublicProfile.
  ///
  /// In en, this message translates to:
  /// **'Public Profile'**
  String get privacyPublicProfile;

  /// No description provided for @privacyShareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share Live Location'**
  String get privacyShareLocation;

  /// No description provided for @privacyAllowAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Allow Analytics'**
  String get privacyAllowAnalytics;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get exportData;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Request data deletion'**
  String get deleteAccount;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @runSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Run saved successfully'**
  String get runSavedSuccessfully;

  /// No description provided for @runSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save run'**
  String get runSaveFailed;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission required'**
  String get locationPermissionRequired;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location service disabled'**
  String get locationServiceDisabled;

  /// No description provided for @runningActive.
  ///
  /// In en, this message translates to:
  /// **'Run Active'**
  String get runningActive;

  /// No description provided for @runningPaused.
  ///
  /// In en, this message translates to:
  /// **'Run Paused'**
  String get runningPaused;

  /// No description provided for @terrain.
  ///
  /// In en, this message translates to:
  /// **'Terrain'**
  String get terrain;

  /// No description provided for @mood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get mood;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @terrainUrban.
  ///
  /// In en, this message translates to:
  /// **'Urban'**
  String get terrainUrban;

  /// No description provided for @terrainTrail.
  ///
  /// In en, this message translates to:
  /// **'Trail'**
  String get terrainTrail;

  /// No description provided for @terrainMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get terrainMixed;

  /// No description provided for @terrainTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get terrainTrack;

  /// No description provided for @moodMotivated.
  ///
  /// In en, this message translates to:
  /// **'Motivated'**
  String get moodMotivated;

  /// No description provided for @moodRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get moodRelaxed;

  /// No description provided for @moodFocused.
  ///
  /// In en, this message translates to:
  /// **'Focused'**
  String get moodFocused;

  /// No description provided for @moodCompetitive.
  ///
  /// In en, this message translates to:
  /// **'Competitive'**
  String get moodCompetitive;

  /// No description provided for @moodTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get moodTired;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @totalRuns.
  ///
  /// In en, this message translates to:
  /// **'Total runs'**
  String get totalRuns;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get birthDate;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @physicalProfile.
  ///
  /// In en, this message translates to:
  /// **'Physical Profile'**
  String get physicalProfile;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @runningGoal.
  ///
  /// In en, this message translates to:
  /// **'Running Goal'**
  String get runningGoal;

  /// No description provided for @goalFitness.
  ///
  /// In en, this message translates to:
  /// **'Stay fit'**
  String get goalFitness;

  /// No description provided for @goalWeight.
  ///
  /// In en, this message translates to:
  /// **'Lose weight'**
  String get goalWeight;

  /// No description provided for @goalSpeed.
  ///
  /// In en, this message translates to:
  /// **'Improve speed'**
  String get goalSpeed;

  /// No description provided for @goalDistance.
  ///
  /// In en, this message translates to:
  /// **'Increase distance'**
  String get goalDistance;

  /// No description provided for @goalCompete.
  ///
  /// In en, this message translates to:
  /// **'Compete'**
  String get goalCompete;

  /// No description provided for @weeklyGoal.
  ///
  /// In en, this message translates to:
  /// **'Weekly Goal'**
  String get weeklyGoal;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them?'**
  String get unsavedChangesMessage;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get profileUpdateFailed;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @nameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameIsRequired;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @preferNotSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get preferNotSay;

  /// No description provided for @fitnessGeneral.
  ///
  /// In en, this message translates to:
  /// **'General fitness'**
  String get fitnessGeneral;

  /// No description provided for @stayActive.
  ///
  /// In en, this message translates to:
  /// **'Stay active'**
  String get stayActive;

  /// No description provided for @weightLoss.
  ///
  /// In en, this message translates to:
  /// **'Weight loss'**
  String get weightLoss;

  /// No description provided for @loseWeight.
  ///
  /// In en, this message translates to:
  /// **'Lose weight'**
  String get loseWeight;

  /// No description provided for @competition.
  ///
  /// In en, this message translates to:
  /// **'Competition'**
  String get competition;

  /// No description provided for @prepareForRaces.
  ///
  /// In en, this message translates to:
  /// **'Prepare for races'**
  String get prepareForRaces;

  /// No description provided for @fun.
  ///
  /// In en, this message translates to:
  /// **'Fun'**
  String get fun;

  /// No description provided for @enjoyRunning.
  ///
  /// In en, this message translates to:
  /// **'Enjoy running'**
  String get enjoyRunning;

  /// No description provided for @totalDistance.
  ///
  /// In en, this message translates to:
  /// **'Total distance'**
  String get totalDistance;

  /// No description provided for @totalDuration.
  ///
  /// In en, this message translates to:
  /// **'Total duration'**
  String get totalDuration;

  /// No description provided for @averagePace.
  ///
  /// In en, this message translates to:
  /// **'Average pace'**
  String get averagePace;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goal;

  /// No description provided for @goalWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly goal'**
  String get goalWeekly;

  /// No description provided for @goalDescription.
  ///
  /// In en, this message translates to:
  /// **'Goal description'**
  String get goalDescription;

  /// No description provided for @goalProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get goalProgress;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
