import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/audit_logger.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/services/notification_scheduler_service.dart';

/// Provider del estado de configuraciones
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Notifier para manejar las configuraciones de la app
class SettingsNotifier extends Notifier<AppSettings> {
  static const String _storageKey = 'app_settings_v1';
  AuditLogger get _auditLogger => ref.read(auditLoggerProvider);
  
  @override
  AppSettings build() {
    // Cargar settings después del primer frame para evitar
    // "modify provider during build" error
    Future.microtask(() => _loadSettings());
    return const AppSettings();
  }

  /// Cargar configuraciones desde SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        state = AppSettings.fromJson(json);
      }
    } catch (e) {
      // Si falla la carga, mantener defaults
    }
  }

  /// Guardar configuraciones en SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(state.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      // Error saving settings
    }
  }

  // ========== APLICACIÓN ==========
  
  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
    await _saveSettings();
  }

  Future<void> setThemeMode(String themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await _saveSettings();
  }

  Future<void> toggleNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _saveSettings();
  }

  // ========== CARRERA ==========
  
  Future<void> setUnits(String units) async {
    state = state.copyWith(units: units);
    await _saveSettings();
  }

  Future<void> setGpsAccuracy(String accuracy) async {
    state = state.copyWith(gpsAccuracy: accuracy);
    await _saveSettings();
  }

  Future<void> setGpsInterval(int intervalMs) async {
    state = state.copyWith(gpsIntervalMs: intervalMs);
    await _saveSettings();
  }

  Future<void> toggleAutoPause(bool enabled) async {
    state = state.copyWith(autoPauseEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setAutoPauseThreshold(double thresholdMs) async {
    state = state.copyWith(autoPauseThresholdMs: thresholdMs);
    await _saveSettings();
  }

  Future<void> toggleVoiceGuidance(bool enabled) async {
    state = state.copyWith(voiceGuidanceEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setVoiceInterval(int seconds) async {
    state = state.copyWith(voiceIntervalSeconds: seconds);
    await _saveSettings();
  }

  // ========== MAPA ==========
  
  Future<void> setMapStyle(String style) async {
    state = state.copyWith(mapStyle: style);
    await _saveSettings();
  }

  Future<void> toggleTraffic(bool enabled) async {
    state = state.copyWith(showTraffic: enabled);
    await _saveSettings();
  }

  Future<void> toggleCompass(bool enabled) async {
    state = state.copyWith(showCompass: enabled);
    await _saveSettings();
  }

  // ========== NOTIFICACIONES ESPECÍFICAS ==========
  
  Future<void> toggleRunReminders(bool enabled) async {
    state = state.copyWith(runRemindersEnabled: enabled);
    await _saveSettings();
    
    // Programar/cancelar recordatorio
    final scheduler = NotificationSchedulerService();
    await scheduler.scheduleRunReminder(
      time: state.runReminderTime,
      enabled: enabled,
    );
  }

  Future<void> setRunReminderTime(String time) async {
    state = state.copyWith(runReminderTime: time);
    await _saveSettings();
    
    // Reprogramar si está habilitado
    if (state.runRemindersEnabled) {
      final scheduler = NotificationSchedulerService();
      await scheduler.scheduleRunReminder(
        time: time,
        enabled: true,
      );
    }
  }

  Future<void> toggleAchievementNotifications(bool enabled) async {
    state = state.copyWith(achievementNotificationsEnabled: enabled);
    await _saveSettings();
  }

  Future<void> toggleWeeklyReport(bool enabled) async {
    state = state.copyWith(weeklyReportEnabled: enabled);
    await _saveSettings();
    
    // Programar/cancelar reporte semanal
    final scheduler = NotificationSchedulerService();
    await scheduler.scheduleWeeklyReport(enabled: enabled);
  }

  // ========== PRIVACIDAD ==========
  
  Future<void> setPublicProfile(bool isPublic) async {
    final previous = state.publicProfile;
    state = state.copyWith(publicProfile: isPublic);
    await _saveSettings();
    if (previous != isPublic) {
      await _auditLogger.log('privacy.public_profile', {
        'previous': previous,
        'next': isPublic,
      });
    }
  }

  Future<void> setShareLocationLive(bool share) async {
    final previous = state.shareLocationLive;
    state = state.copyWith(shareLocationLive: share);
    await _saveSettings();
    if (previous != share) {
      await _auditLogger.log('privacy.share_location_live', {
        'previous': previous,
        'next': share,
      });
    }
  }

  Future<void> setAllowAnalytics(bool allow) async {
    final previous = state.allowAnalytics;
    state = state.copyWith(allowAnalytics: allow);
    await _saveSettings();
    if (previous != allow) {
      await _auditLogger.log('privacy.allow_analytics', {
        'previous': previous,
        'next': allow,
      });
    }
  }

  // ========== FILTRO DE HOGAR ==========
  
  Future<void> toggleHomeFilter(bool enabled) async {
    final previous = state.homeFilterEnabled;
    state = state.copyWith(homeFilterEnabled: enabled);
    await _saveSettings();
    if (previous != enabled) {
      await _auditLogger.log('privacy.home_filter.toggle', {
        'previous': previous,
        'next': enabled,
      });
    }
  }

  Future<void> setHomeLocation({
    required double latitude,
    required double longitude,
  }) async {
    final prevLat = state.homeLatitude;
    final prevLon = state.homeLongitude;
    state = state.copyWith(
      homeLatitude: latitude,
      homeLongitude: longitude,
    );
    await _saveSettings();
    await _auditLogger.log('privacy.home_filter.location', {
      'previous': prevLat != null && prevLon != null
          ? {'lat': prevLat, 'lon': prevLon}
          : null,
      'next': {'lat': latitude, 'lon': longitude},
    });
  }

  Future<void> setHomeRadius(double radiusMeters) async {
    final previous = state.homeRadiusMeters;
    state = state.copyWith(homeRadiusMeters: radiusMeters);
    await _saveSettings();
    if ((previous - radiusMeters).abs() >= 0.1) {
      await _auditLogger.log('privacy.home_filter.radius', {
        'previous': previous,
        'next': radiusMeters,
      });
    }
  }

  Future<void> clearHomeLocation() async {
    final hadLocation = state.homeLatitude != null && state.homeLongitude != null;
    state = state.copyWith(
      homeFilterEnabled: false,
      homeLatitude: null,
      homeLongitude: null,
    );
    await _saveSettings();
    await _auditLogger.log('privacy.home_filter.cleared', {
      'hadLocation': hadLocation,
    });
  }

  // ========== UTILIDADES ==========
  
  /// Restablecer todas las configuraciones a valores por defecto
  Future<void> resetToDefaults() async {
    state = const AppSettings();
    await _saveSettings();
  }

  /// Forzar guardado (útil para testing)
  Future<void> forceSave() async {
    await _saveSettings();
  }
}
