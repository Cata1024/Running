/// Configuraciones de la aplicación
/// 
/// Todas las preferencias del usuario almacenadas de forma persistente
class AppSettings {
  // Aplicación
  final String language;              // 'es', 'en'
  final String themeMode;             // 'system', 'light', 'dark'
  final bool notificationsEnabled;
  
  // Carrera
  final String units;                 // 'metric', 'imperial'
  final String gpsAccuracy;           // 'high', 'balanced', 'low'
  final int gpsIntervalMs;            // milliseconds (500-5000)
  final bool autoPauseEnabled;
  final double autoPauseThresholdMs;  // m/s - velocidad mínima antes de pausar
  final bool voiceGuidanceEnabled;
  final int voiceIntervalSeconds;     // cada cuántos segundos da feedback de voz
  
  // Mapa
  final String mapStyle;              // 'standard', 'satellite', 'terrain', 'hybrid'
  final bool showTraffic;
  final bool showCompass;
  
  // Notificaciones específicas
  final bool runRemindersEnabled;
  final String runReminderTime;       // 'HH:mm' formato 24h
  final bool achievementNotificationsEnabled;
  final bool weeklyReportEnabled;
  
  // Privacidad
  final bool publicProfile;
  final bool shareLocationLive;
  final bool allowAnalytics;
  
  // Filtro de hogar
  final bool homeFilterEnabled;
  final double? homeLatitude;
  final double? homeLongitude;
  final double homeRadiusMeters;  // Radio en metros (50-500m)
  
  const AppSettings({
    // Defaults
    this.language = 'es',
    this.themeMode = 'system',
    this.notificationsEnabled = true,
    this.units = 'metric',
    this.gpsAccuracy = 'high',
    this.gpsIntervalMs = 1000,
    this.autoPauseEnabled = false,
    this.autoPauseThresholdMs = 0.5,
    this.voiceGuidanceEnabled = false,
    this.voiceIntervalSeconds = 60,
    this.mapStyle = 'standard',
    this.showTraffic = false,
    this.showCompass = true,
    this.runRemindersEnabled = false,
    this.runReminderTime = '18:00',
    this.achievementNotificationsEnabled = true,
    this.weeklyReportEnabled = true,
    this.publicProfile = false,
    this.shareLocationLive = false,
    this.allowAnalytics = true,
    this.homeFilterEnabled = false,
    this.homeLatitude,
    this.homeLongitude,
    this.homeRadiusMeters = 100.0,
  });

  /// Crear desde JSON (SharedPreferences)
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      language: json['language'] as String? ?? 'es',
      themeMode: json['themeMode'] as String? ?? 'system',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      units: json['units'] as String? ?? 'metric',
      gpsAccuracy: json['gpsAccuracy'] as String? ?? 'high',
      gpsIntervalMs: json['gpsIntervalMs'] as int? ?? 1000,
      autoPauseEnabled: json['autoPauseEnabled'] as bool? ?? false,
      autoPauseThresholdMs: (json['autoPauseThresholdMs'] as num?)?.toDouble() ?? 0.5,
      voiceGuidanceEnabled: json['voiceGuidanceEnabled'] as bool? ?? false,
      voiceIntervalSeconds: json['voiceIntervalSeconds'] as int? ?? 60,
      mapStyle: json['mapStyle'] as String? ?? 'standard',
      showTraffic: json['showTraffic'] as bool? ?? false,
      showCompass: json['showCompass'] as bool? ?? true,
      runRemindersEnabled: json['runRemindersEnabled'] as bool? ?? false,
      runReminderTime: json['runReminderTime'] as String? ?? '18:00',
      achievementNotificationsEnabled: json['achievementNotificationsEnabled'] as bool? ?? true,
      weeklyReportEnabled: json['weeklyReportEnabled'] as bool? ?? true,
      publicProfile: json['publicProfile'] as bool? ?? false,
      shareLocationLive: json['shareLocationLive'] as bool? ?? false,
      allowAnalytics: json['allowAnalytics'] as bool? ?? true,
      homeFilterEnabled: json['homeFilterEnabled'] as bool? ?? false,
      homeLatitude: (json['homeLatitude'] as num?)?.toDouble(),
      homeLongitude: (json['homeLongitude'] as num?)?.toDouble(),
      homeRadiusMeters: (json['homeRadiusMeters'] as num?)?.toDouble() ?? 100.0,
    );
  }

  /// Convertir a JSON para guardar
  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'themeMode': themeMode,
      'notificationsEnabled': notificationsEnabled,
      'units': units,
      'gpsAccuracy': gpsAccuracy,
      'gpsIntervalMs': gpsIntervalMs,
      'autoPauseEnabled': autoPauseEnabled,
      'autoPauseThresholdMs': autoPauseThresholdMs,
      'voiceGuidanceEnabled': voiceGuidanceEnabled,
      'voiceIntervalSeconds': voiceIntervalSeconds,
      'mapStyle': mapStyle,
      'showTraffic': showTraffic,
      'showCompass': showCompass,
      'runRemindersEnabled': runRemindersEnabled,
      'runReminderTime': runReminderTime,
      'achievementNotificationsEnabled': achievementNotificationsEnabled,
      'weeklyReportEnabled': weeklyReportEnabled,
      'publicProfile': publicProfile,
      'shareLocationLive': shareLocationLive,
      'allowAnalytics': allowAnalytics,
      'homeFilterEnabled': homeFilterEnabled,
      'homeLatitude': homeLatitude,
      'homeLongitude': homeLongitude,
      'homeRadiusMeters': homeRadiusMeters,
    };
  }

  /// Copiar con cambios
  AppSettings copyWith({
    String? language,
    String? themeMode,
    bool? notificationsEnabled,
    String? units,
    String? gpsAccuracy,
    int? gpsIntervalMs,
    bool? autoPauseEnabled,
    double? autoPauseThresholdMs,
    bool? voiceGuidanceEnabled,
    int? voiceIntervalSeconds,
    String? mapStyle,
    bool? showTraffic,
    bool? showCompass,
    bool? runRemindersEnabled,
    String? runReminderTime,
    bool? achievementNotificationsEnabled,
    bool? weeklyReportEnabled,
    bool? publicProfile,
    bool? shareLocationLive,
    bool? allowAnalytics,
    bool? homeFilterEnabled,
    double? homeLatitude,
    double? homeLongitude,
    double? homeRadiusMeters,
  }) {
    return AppSettings(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      units: units ?? this.units,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      gpsIntervalMs: gpsIntervalMs ?? this.gpsIntervalMs,
      autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
      autoPauseThresholdMs: autoPauseThresholdMs ?? this.autoPauseThresholdMs,
      voiceGuidanceEnabled: voiceGuidanceEnabled ?? this.voiceGuidanceEnabled,
      voiceIntervalSeconds: voiceIntervalSeconds ?? this.voiceIntervalSeconds,
      mapStyle: mapStyle ?? this.mapStyle,
      showTraffic: showTraffic ?? this.showTraffic,
      showCompass: showCompass ?? this.showCompass,
      runRemindersEnabled: runRemindersEnabled ?? this.runRemindersEnabled,
      runReminderTime: runReminderTime ?? this.runReminderTime,
      achievementNotificationsEnabled: achievementNotificationsEnabled ?? this.achievementNotificationsEnabled,
      weeklyReportEnabled: weeklyReportEnabled ?? this.weeklyReportEnabled,
      publicProfile: publicProfile ?? this.publicProfile,
      shareLocationLive: shareLocationLive ?? this.shareLocationLive,
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      homeFilterEnabled: homeFilterEnabled ?? this.homeFilterEnabled,
      homeLatitude: homeLatitude ?? this.homeLatitude,
      homeLongitude: homeLongitude ?? this.homeLongitude,
      homeRadiusMeters: homeRadiusMeters ?? this.homeRadiusMeters,
    );
  }

  /// Helpers para conversión de unidades
  double convertDistance(double meters) {
    if (units == 'imperial') {
      return meters * 0.000621371; // a millas
    }
    return meters / 1000; // a kilómetros
  }

  String get distanceUnit => units == 'imperial' ? 'mi' : 'km';
  String get distanceLongUnit => units == 'imperial' ? 'millas' : 'kilómetros';
  
  double convertSpeed(double metersPerSecond) {
    if (units == 'imperial') {
      return metersPerSecond * 2.23694; // a mph
    }
    return metersPerSecond * 3.6; // a km/h
  }

  String get speedUnit => units == 'imperial' ? 'mph' : 'km/h';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.language == language &&
        other.themeMode == themeMode &&
        other.notificationsEnabled == notificationsEnabled &&
        other.units == units &&
        other.gpsAccuracy == gpsAccuracy &&
        other.gpsIntervalMs == gpsIntervalMs &&
        other.autoPauseEnabled == autoPauseEnabled &&
        other.autoPauseThresholdMs == autoPauseThresholdMs &&
        other.voiceGuidanceEnabled == voiceGuidanceEnabled &&
        other.voiceIntervalSeconds == voiceIntervalSeconds &&
        other.mapStyle == mapStyle &&
        other.showTraffic == showTraffic &&
        other.showCompass == showCompass &&
        other.runRemindersEnabled == runRemindersEnabled &&
        other.runReminderTime == runReminderTime &&
        other.achievementNotificationsEnabled == achievementNotificationsEnabled &&
        other.weeklyReportEnabled == weeklyReportEnabled &&
        other.publicProfile == publicProfile &&
        other.shareLocationLive == shareLocationLive &&
        other.allowAnalytics == allowAnalytics;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      language,
      themeMode,
      notificationsEnabled,
      units,
      gpsAccuracy,
      gpsIntervalMs,
      autoPauseEnabled,
      autoPauseThresholdMs,
      voiceGuidanceEnabled,
      voiceIntervalSeconds,
      mapStyle,
      showTraffic,
      showCompass,
      runRemindersEnabled,
      runReminderTime,
      achievementNotificationsEnabled,
      weeklyReportEnabled,
      publicProfile,
      shareLocationLive,
      allowAnalytics,
    ]);
  }
}
