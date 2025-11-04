import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_settings.dart';

/// Provider del estado de configuraciones
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Notifier para manejar las configuraciones de la app
class SettingsNotifier extends Notifier<AppSettings> {
  static const String _storageKey = 'app_settings_v1';
  
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
  }

  Future<void> setRunReminderTime(String time) async {
    state = state.copyWith(runReminderTime: time);
    await _saveSettings();
  }

  Future<void> toggleAchievementNotifications(bool enabled) async {
    state = state.copyWith(achievementNotificationsEnabled: enabled);
    await _saveSettings();
  }

  Future<void> toggleWeeklyReport(bool enabled) async {
    state = state.copyWith(weeklyReportEnabled: enabled);
    await _saveSettings();
  }

  // ========== PRIVACIDAD ==========
  
  Future<void> setPublicProfile(bool isPublic) async {
    state = state.copyWith(publicProfile: isPublic);
    await _saveSettings();
  }

  Future<void> setShareLocationLive(bool share) async {
    state = state.copyWith(shareLocationLive: share);
    await _saveSettings();
  }

  Future<void> setAllowAnalytics(bool allow) async {
    state = state.copyWith(allowAnalytics: allow);
    await _saveSettings();
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
