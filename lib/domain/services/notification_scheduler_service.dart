import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Servicio para programar notificaciones (recordatorios, logros, reportes)
class NotificationSchedulerService {
  static final NotificationSchedulerService _instance = NotificationSchedulerService._internal();
  factory NotificationSchedulerService() => _instance;
  NotificationSchedulerService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // IDs de notificaciones
  static const int _runReminderNotificationId = 2001;
  static const int _achievementNotificationId = 2002;
  static const int _weeklyReportNotificationId = 2003;

  // Canales
  static const String _remindersChannelId = 'run_reminders_channel';
  static const String _achievementsChannelId = 'achievements_channel';
  static const String _reportsChannelId = 'reports_channel';

  /// Inicializar el servicio
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inicializar zonas horarias
      tz.initializeTimeZones();
      
      // Configuración Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configuración iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      debugPrint('✅ NotificationSchedulerService inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando NotificationSchedulerService: $e');
    }
  }

  /// Programar recordatorio diario de carrera
  Future<void> scheduleRunReminder({
    required String time, // Formato "HH:mm" (24h)
    bool enabled = true,
  }) async {
    if (!_isInitialized) await initialize();

    if (!enabled) {
      await cancelRunReminder();
      return;
    }

    try {
      // Parsear hora
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Crear fecha/hora para hoy
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Si ya pasó la hora de hoy, programar para mañana
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Detalles Android
      const androidDetails = AndroidNotificationDetails(
        _remindersChannelId,
        'Recordatorios de Carrera',
        channelDescription: 'Recordatorios diarios para salir a correr',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      // Detalles iOS
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Programar notificación diaria
      await _notifications.zonedSchedule(
        _runReminderNotificationId,
        '🏃 ¡Hora de correr!',
        '¿Listo para tu carrera de hoy? ¡Vamos!',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repetir diariamente
      );

      debugPrint('✅ Recordatorio programado para las $time');
    } catch (e) {
      debugPrint('❌ Error programando recordatorio: $e');
    }
  }

  /// Cancelar recordatorio de carrera
  Future<void> cancelRunReminder() async {
    await _notifications.cancel(_runReminderNotificationId);
    debugPrint('🔕 Recordatorio de carrera cancelado');
  }

  /// Mostrar notificación de logro desbloqueado
  Future<void> showAchievementNotification({
    required String title,
    required String description,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        _achievementsChannelId,
        'Logros y Niveles',
        channelDescription: 'Notificaciones de logros desbloqueados',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _achievementNotificationId,
        '🏆 $title',
        description,
        notificationDetails,
      );

      debugPrint('🏆 Notificación de logro mostrada: $title');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación de logro: $e');
    }
  }

  /// Programar reporte semanal (cada lunes a las 9:00 AM)
  Future<void> scheduleWeeklyReport({
    bool enabled = true,
  }) async {
    if (!_isInitialized) await initialize();

    if (!enabled) {
      await cancelWeeklyReport();
      return;
    }

    try {
      // Encontrar el próximo lunes a las 9:00 AM
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        9, // 9:00 AM
        0,
      );

      // Avanzar hasta el próximo lunes
      while (scheduledDate.weekday != DateTime.monday || scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        _reportsChannelId,
        'Reportes Semanales',
        channelDescription: 'Resumen semanal de tu actividad',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        _weeklyReportNotificationId,
        '📊 Reporte Semanal',
        '¡Mira tu progreso de la semana pasada!',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // Repetir semanalmente
      );

      debugPrint('✅ Reporte semanal programado para los lunes a las 9:00 AM');
    } catch (e) {
      debugPrint('❌ Error programando reporte semanal: $e');
    }
  }

  /// Cancelar reporte semanal
  Future<void> cancelWeeklyReport() async {
    await _notifications.cancel(_weeklyReportNotificationId);
    debugPrint('🔕 Reporte semanal cancelado');
  }

  /// Cancelar todas las notificaciones programadas
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    debugPrint('🔕 Todas las notificaciones canceladas');
  }

  /// Ver notificaciones pendientes (para debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Handler cuando el usuario toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notificación tocada: ${response.id}');
    
    // Aquí puedes navegar a pantallas específicas según el tipo de notificación
    switch (response.id) {
      case _runReminderNotificationId:
        debugPrint('→ Abrir pantalla de carrera');
        break;
      case _achievementNotificationId:
        debugPrint('→ Abrir pantalla de logros');
        break;
      case _weeklyReportNotificationId:
        debugPrint('→ Abrir pantalla de estadísticas');
        break;
    }
  }
}
