import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Servicio para mostrar notificación persistente durante la carrera
/// 
/// Muestra tiempo, distancia y velocidad en tiempo real
/// Permite al usuario ver el progreso sin tener la app abierta
class RunNotificationService {
  static final RunNotificationService _instance = RunNotificationService._internal();
  factory RunNotificationService() => _instance;
  RunNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  void Function(String actionId)? _actionHandler;

  static const String _channelId = 'running_tracking_channel';
  static const String _channelName = 'Seguimiento de Carrera';
  static const String _channelDescription = 'Notificación persistente durante la carrera';
  static const int _notificationId = 1001;

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configuración Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configuración iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: false,
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
      debugPrint('✅ RunNotificationService inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando notificaciones: $e');
    }
  }

  void registerActionHandler(void Function(String actionId)? handler) {
    _actionHandler = handler;
  }

  /// Solicitar permisos (principalmente para Android 13+)
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: false,
        );
        return granted ?? false;
      }
    }
    return true;
  }

  /// Mostrar/actualizar notificación de carrera activa
  Future<void> showRunningNotification({
    required Duration elapsed,
    required double distanceKm,
    required double currentSpeedKmh,
    bool isPaused = false,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Formatear tiempo
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);
    final timeStr = hours > 0
        ? '${hours}h ${minutes}m ${seconds}s'
        : '${minutes}m ${seconds}s';

    // Formatear distancia
    final distanceStr = distanceKm >= 1.0
        ? '${distanceKm.toStringAsFixed(2)} km'
        : '${(distanceKm * 1000).toStringAsFixed(0)} m';

    // Formatear velocidad
    final speedStr = '${currentSpeedKmh.toStringAsFixed(1)} km/h';

    // Calcular ritmo (min/km)
    final paceMinPerKm = currentSpeedKmh > 0 ? 60 / currentSpeedKmh : 0.0;
    final paceMin = paceMinPerKm.floor();
    final paceSec = ((paceMinPerKm - paceMin) * 60).round();
    final paceStr = '$paceMin:${paceSec.toString().padLeft(2, '0')} min/km';

    final title = isPaused ? '⏸️ Carrera en Pausa' : '🏃 Carrera Activa';
    final body = '$timeStr • $distanceStr • $speedStr';

    // Detalles Android
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low, // Low para que no haga sonido
      priority: Priority.high,
      ongoing: true, // No se puede deslizar para cerrar
      autoCancel: false,
      showWhen: false,
      usesChronometer: !isPaused, // Mostrar cronómetro si no está pausado
      chronometerCountDown: false,
      styleInformation: BigTextStyleInformation(
        '$body\nRitmo: $paceStr',
        contentTitle: title,
        summaryText: 'Territory Run',
      ),
      // Acciones
      actions: isPaused
          ? <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'resume',
                '▶️ Reanudar',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'stop',
                '⏹️ Detener',
                showsUserInterface: true,
              ),
            ]
          : <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'pause',
                '⏸️ Pausar',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'stop',
                '⏹️ Detener',
                showsUserInterface: true,
              ),
            ],
    );

    // Detalles iOS
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
      interruptionLevel: InterruptionLevel.passive,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _notificationId,
      title,
      body,
      notificationDetails,
    );
  }

  /// Cancelar notificación de carrera
  Future<void> cancelRunningNotification() async {
    await _notifications.cancel(_notificationId);
    debugPrint('🔕 Notificación de carrera cancelada');
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Handler cuando el usuario toca la notificación
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notificación tocada: ${response.actionId}');
    
    // Las acciones (pause, resume, stop) se manejarán en el run_screen
    // mediante un callback o stream
    
    // Por ahora solo loguear
    if (response.actionId != null) {
      debugPrint('Acción: ${response.actionId}');
      final action = response.actionId!;
      try {
        _actionHandler?.call(action);
      } catch (_) {}
    }
  }

  /// Verificar si las notificaciones están habilitadas
  Future<bool> areNotificationsEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled();
        return enabled ?? false;
      }
    }
    return true; // iOS siempre retorna true si se concedieron permisos
  }
}
