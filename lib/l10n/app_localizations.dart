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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  /// In es, this message translates to:
  /// **'Territory Run'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido'**
  String get welcome;

  /// No description provided for @getStarted.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get getStarted;

  /// No description provided for @signIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar Sesión'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get email;

  /// No description provided for @password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta?'**
  String get alreadyHaveAccount;

  /// No description provided for @home.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get home;

  /// No description provided for @run.
  ///
  /// In es, this message translates to:
  /// **'Correr'**
  String get run;

  /// No description provided for @history.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get history;

  /// No description provided for @profile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settings;

  /// No description provided for @startRun.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Carrera'**
  String get startRun;

  /// No description provided for @pauseRun.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get pauseRun;

  /// No description provided for @resumeRun.
  ///
  /// In es, this message translates to:
  /// **'Reanudar'**
  String get resumeRun;

  /// No description provided for @stopRun.
  ///
  /// In es, this message translates to:
  /// **'Detener'**
  String get stopRun;

  /// No description provided for @saveRun.
  ///
  /// In es, this message translates to:
  /// **'Guardar Carrera'**
  String get saveRun;

  /// No description provided for @discardRun.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get discardRun;

  /// No description provided for @distance.
  ///
  /// In es, this message translates to:
  /// **'Distancia'**
  String get distance;

  /// No description provided for @duration.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get duration;

  /// No description provided for @pace.
  ///
  /// In es, this message translates to:
  /// **'Ritmo'**
  String get pace;

  /// No description provided for @speed.
  ///
  /// In es, this message translates to:
  /// **'Velocidad'**
  String get speed;

  /// No description provided for @calories.
  ///
  /// In es, this message translates to:
  /// **'Calorías'**
  String get calories;

  /// No description provided for @elevation.
  ///
  /// In es, this message translates to:
  /// **'Elevación'**
  String get elevation;

  /// No description provided for @km.
  ///
  /// In es, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @mi.
  ///
  /// In es, this message translates to:
  /// **'mi'**
  String get mi;

  /// No description provided for @meters.
  ///
  /// In es, this message translates to:
  /// **'metros'**
  String get meters;

  /// No description provided for @feet.
  ///
  /// In es, this message translates to:
  /// **'pies'**
  String get feet;

  /// No description provided for @today.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In es, this message translates to:
  /// **'Este mes'**
  String get thisMonth;

  /// No description provided for @allTime.
  ///
  /// In es, this message translates to:
  /// **'Todo el tiempo'**
  String get allTime;

  /// No description provided for @noRunsYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes carreras'**
  String get noRunsYet;

  /// No description provided for @startFirstRun.
  ///
  /// In es, this message translates to:
  /// **'¡Inicia tu primera carrera!'**
  String get startFirstRun;

  /// No description provided for @settingsApp.
  ///
  /// In es, this message translates to:
  /// **'Aplicación'**
  String get settingsApp;

  /// No description provided for @settingsTheme.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @settingsLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @settingsNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get settingsNotifications;

  /// No description provided for @settingsUnits.
  ///
  /// In es, this message translates to:
  /// **'Unidades'**
  String get settingsUnits;

  /// No description provided for @settingsGps.
  ///
  /// In es, this message translates to:
  /// **'GPS'**
  String get settingsGps;

  /// No description provided for @settingsPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Privacidad y Seguridad'**
  String get settingsPrivacy;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @unitsMetric.
  ///
  /// In es, this message translates to:
  /// **'Sistema Métrico'**
  String get unitsMetric;

  /// No description provided for @unitsImperial.
  ///
  /// In es, this message translates to:
  /// **'Sistema Imperial'**
  String get unitsImperial;

  /// No description provided for @gpsAccuracy.
  ///
  /// In es, this message translates to:
  /// **'Precisión'**
  String get gpsAccuracy;

  /// No description provided for @gpsAccuracyLow.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get gpsAccuracyLow;

  /// No description provided for @gpsAccuracyBalanced.
  ///
  /// In es, this message translates to:
  /// **'Equilibrada'**
  String get gpsAccuracyBalanced;

  /// No description provided for @gpsAccuracyHigh.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get gpsAccuracyHigh;

  /// No description provided for @autoPause.
  ///
  /// In es, this message translates to:
  /// **'Auto Pausa'**
  String get autoPause;

  /// No description provided for @autoPauseDescription.
  ///
  /// In es, this message translates to:
  /// **'Pausar automáticamente cuando te detienes'**
  String get autoPauseDescription;

  /// No description provided for @notificationsEnabled.
  ///
  /// In es, this message translates to:
  /// **'Habilitar notificaciones'**
  String get notificationsEnabled;

  /// No description provided for @notificationsRunReminders.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios de carrera'**
  String get notificationsRunReminders;

  /// No description provided for @notificationsAchievements.
  ///
  /// In es, this message translates to:
  /// **'Logros y niveles'**
  String get notificationsAchievements;

  /// No description provided for @notificationsWeeklyReport.
  ///
  /// In es, this message translates to:
  /// **'Reporte semanal'**
  String get notificationsWeeklyReport;

  /// No description provided for @privacyPublicProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil Público'**
  String get privacyPublicProfile;

  /// No description provided for @privacyShareLocation.
  ///
  /// In es, this message translates to:
  /// **'Compartir Ubicación en Vivo'**
  String get privacyShareLocation;

  /// No description provided for @privacyAllowAnalytics.
  ///
  /// In es, this message translates to:
  /// **'Permitir Analytics'**
  String get privacyAllowAnalytics;

  /// No description provided for @exportData.
  ///
  /// In es, this message translates to:
  /// **'Exportar mis datos'**
  String get exportData;

  /// No description provided for @deleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Solicitar eliminación de datos'**
  String get deleteAccount;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get done;

  /// No description provided for @error.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In es, this message translates to:
  /// **'Éxito'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// No description provided for @runSavedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Carrera guardada exitosamente'**
  String get runSavedSuccessfully;

  /// No description provided for @runSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar la carrera'**
  String get runSaveFailed;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In es, this message translates to:
  /// **'Se requiere permiso de ubicación'**
  String get locationPermissionRequired;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'Permiso de ubicación denegado'**
  String get locationPermissionDenied;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In es, this message translates to:
  /// **'Servicio de ubicación desactivado'**
  String get locationServiceDisabled;

  /// No description provided for @runningActive.
  ///
  /// In es, this message translates to:
  /// **'Carrera Activa'**
  String get runningActive;

  /// No description provided for @runningPaused.
  ///
  /// In es, this message translates to:
  /// **'Carrera en Pausa'**
  String get runningPaused;

  /// No description provided for @terrain.
  ///
  /// In es, this message translates to:
  /// **'Terreno'**
  String get terrain;

  /// No description provided for @mood.
  ///
  /// In es, this message translates to:
  /// **'Estado de ánimo'**
  String get mood;

  /// No description provided for @weather.
  ///
  /// In es, this message translates to:
  /// **'Clima'**
  String get weather;

  /// No description provided for @terrainUrban.
  ///
  /// In es, this message translates to:
  /// **'Urbano'**
  String get terrainUrban;

  /// No description provided for @terrainTrail.
  ///
  /// In es, this message translates to:
  /// **'Trail'**
  String get terrainTrail;

  /// No description provided for @terrainMixed.
  ///
  /// In es, this message translates to:
  /// **'Mixto'**
  String get terrainMixed;

  /// No description provided for @terrainTrack.
  ///
  /// In es, this message translates to:
  /// **'Pista'**
  String get terrainTrack;

  /// No description provided for @moodMotivated.
  ///
  /// In es, this message translates to:
  /// **'Motivado'**
  String get moodMotivated;

  /// No description provided for @moodRelaxed.
  ///
  /// In es, this message translates to:
  /// **'Relajado'**
  String get moodRelaxed;

  /// No description provided for @moodFocused.
  ///
  /// In es, this message translates to:
  /// **'Enfocado'**
  String get moodFocused;

  /// No description provided for @moodCompetitive.
  ///
  /// In es, this message translates to:
  /// **'Competitivo'**
  String get moodCompetitive;

  /// No description provided for @moodTired.
  ///
  /// In es, this message translates to:
  /// **'Cansado'**
  String get moodTired;

  /// No description provided for @level.
  ///
  /// In es, this message translates to:
  /// **'Nivel'**
  String get level;

  /// No description provided for @experience.
  ///
  /// In es, this message translates to:
  /// **'Experiencia'**
  String get experience;

  /// No description provided for @achievements.
  ///
  /// In es, this message translates to:
  /// **'Logros'**
  String get achievements;

  /// No description provided for @statistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get statistics;

  /// No description provided for @totalRuns.
  ///
  /// In es, this message translates to:
  /// **'Carreras totales'**
  String get totalRuns;

  /// No description provided for @editProfile.
  ///
  /// In es, this message translates to:
  /// **'Editar Perfil'**
  String get editProfile;

  /// No description provided for @basicInformation.
  ///
  /// In es, this message translates to:
  /// **'Información Básica'**
  String get basicInformation;

  /// No description provided for @fullName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get fullName;

  /// No description provided for @birthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get birthDate;

  /// No description provided for @gender.
  ///
  /// In es, this message translates to:
  /// **'Género'**
  String get gender;

  /// No description provided for @genderMale.
  ///
  /// In es, this message translates to:
  /// **'Masculino'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In es, this message translates to:
  /// **'Femenino'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get genderOther;

  /// No description provided for @physicalProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil Físico'**
  String get physicalProfile;

  /// No description provided for @weight.
  ///
  /// In es, this message translates to:
  /// **'Peso'**
  String get weight;

  /// No description provided for @height.
  ///
  /// In es, this message translates to:
  /// **'Altura'**
  String get height;

  /// No description provided for @runningGoal.
  ///
  /// In es, this message translates to:
  /// **'Objetivo de Carrera'**
  String get runningGoal;

  /// No description provided for @goalFitness.
  ///
  /// In es, this message translates to:
  /// **'Mantenerme en forma'**
  String get goalFitness;

  /// No description provided for @goalWeight.
  ///
  /// In es, this message translates to:
  /// **'Perder peso'**
  String get goalWeight;

  /// No description provided for @goalSpeed.
  ///
  /// In es, this message translates to:
  /// **'Mejorar velocidad'**
  String get goalSpeed;

  /// No description provided for @goalDistance.
  ///
  /// In es, this message translates to:
  /// **'Aumentar distancia'**
  String get goalDistance;

  /// No description provided for @goalCompete.
  ///
  /// In es, this message translates to:
  /// **'Competir'**
  String get goalCompete;

  /// No description provided for @weeklyGoal.
  ///
  /// In es, this message translates to:
  /// **'Meta Semanal'**
  String get weeklyGoal;

  /// No description provided for @unsavedChanges.
  ///
  /// In es, this message translates to:
  /// **'Cambios sin guardar'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In es, this message translates to:
  /// **'Tienes cambios sin guardar. ¿Deseas descartarlos?'**
  String get unsavedChangesMessage;

  /// No description provided for @discard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In es, this message translates to:
  /// **'Seguir editando'**
  String get keepEditing;

  /// No description provided for @profileUpdated.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado'**
  String get profileUpdated;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar el perfil'**
  String get profileUpdateFailed;

  /// No description provided for @yourName.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get yourName;

  /// No description provided for @nameIsRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre es requerido'**
  String get nameIsRequired;

  /// No description provided for @selectDate.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar fecha'**
  String get selectDate;

  /// No description provided for @male.
  ///
  /// In es, this message translates to:
  /// **'Masculino'**
  String get male;

  /// No description provided for @female.
  ///
  /// In es, this message translates to:
  /// **'Femenino'**
  String get female;

  /// No description provided for @other.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get other;

  /// No description provided for @preferNotSay.
  ///
  /// In es, this message translates to:
  /// **'Prefiero no decir'**
  String get preferNotSay;

  /// No description provided for @fitnessGeneral.
  ///
  /// In es, this message translates to:
  /// **'Condición física'**
  String get fitnessGeneral;

  /// No description provided for @stayActive.
  ///
  /// In es, this message translates to:
  /// **'Mantenerme activo'**
  String get stayActive;

  /// No description provided for @weightLoss.
  ///
  /// In es, this message translates to:
  /// **'Pérdida de peso'**
  String get weightLoss;

  /// No description provided for @loseWeight.
  ///
  /// In es, this message translates to:
  /// **'Perder peso'**
  String get loseWeight;

  /// No description provided for @competition.
  ///
  /// In es, this message translates to:
  /// **'Competencia'**
  String get competition;

  /// No description provided for @prepareForRaces.
  ///
  /// In es, this message translates to:
  /// **'Prepararme para carreras'**
  String get prepareForRaces;

  /// No description provided for @fun.
  ///
  /// In es, this message translates to:
  /// **'Diversión'**
  String get fun;

  /// No description provided for @enjoyRunning.
  ///
  /// In es, this message translates to:
  /// **'Disfrutar corriendo'**
  String get enjoyRunning;

  /// No description provided for @totalDistance.
  ///
  /// In es, this message translates to:
  /// **'Distancia total'**
  String get totalDistance;

  /// No description provided for @totalDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración total'**
  String get totalDuration;

  /// No description provided for @averagePace.
  ///
  /// In es, this message translates to:
  /// **'Ritmo promedio'**
  String get averagePace;

  /// No description provided for @goal.
  ///
  /// In es, this message translates to:
  /// **'Meta'**
  String get goal;

  /// No description provided for @goalWeekly.
  ///
  /// In es, this message translates to:
  /// **'Meta semanal'**
  String get goalWeekly;

  /// No description provided for @goalProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get goalProgress;

  /// No description provided for @about.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get about;

  /// No description provided for @version.
  ///
  /// In es, this message translates to:
  /// **'Versión'**
  String get version;

  /// No description provided for @helpSupport.
  ///
  /// In es, this message translates to:
  /// **'Ayuda y Soporte'**
  String get helpSupport;

  /// No description provided for @rateApp.
  ///
  /// In es, this message translates to:
  /// **'Calificar App'**
  String get rateApp;

  /// No description provided for @privacyPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de Privacidad'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In es, this message translates to:
  /// **'Términos de Servicio'**
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
