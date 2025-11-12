import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:running/l10n/app_localizations.dart';
import 'core/env_config.dart';
import 'core/theme/app_theme.dart';
import 'presentation/navigation/app_router.dart';
import 'presentation/widgets/achievement_notification.dart';
import 'presentation/providers/app_providers.dart';
import 'core/widgets/error_state.dart';

/// 🏃 Entry point principal
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización paralela controlada
  final initializationFuture = _initializeApp();

  runApp(
    ProviderScope(
      child: RunningBootstrapper(initializationFuture: initializationFuture),
    ),
  );
}

/// 🔧 Inicialización global de entorno, Firebase, localización, etc.
Future<void> _initializeApp() async {
  await dotenv.load(fileName: '.env');

  final baseApiUrl = EnvConfig.instance.backendApiUrl;
  if (baseApiUrl.isEmpty) {
    throw StateError('BASE_API_URL is not set in .env');
  }

  await runZonedGuarded(() async {
    await initFirebase();

    // ✅ Activación de App Check (modo debug / producción)
    //final androidProvider = kDebugMode
    //    ? const AndroidDebugProvider()
    //    : const AndroidPlayIntegrityProvider();

    //final androidProvider = const AndroidDebugProvider();

    //await FirebaseAppCheck.instance.activate(
    //  providerAndroid: androidProvider,
    //);

    // Manejo de errores globales → Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });

  // 🌎 Inicializa formatos de fecha
  await Future.wait([
    initializeDateFormatting('es'),
    initializeDateFormatting('en'),
  ]);

  await configureGoogleMaps();

  // 🔒 Bloquea orientación en retrato
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

/// 📦 Precarga imágenes críticas (logo, splash, etc.)
Future<void> precacheAppImages(BuildContext context) async {
  try {
    await Future.wait([
      // Ejemplo:
      // precacheImage(const AssetImage('assets/images/logo.png'), context),
    ]);
  } catch (e) {
    debugPrint('⚠️ Error precaching images: $e');
  }
}

/// 🌐 Widget bootstrapper (muestra splash / error / app)
class RunningBootstrapper extends StatefulWidget {
  final Future<void> initializationFuture;

  const RunningBootstrapper({super.key, required this.initializationFuture});

  @override
  State<RunningBootstrapper> createState() => _RunningBootstrapperState();
}

class _RunningBootstrapperState extends State<RunningBootstrapper> {
  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.initializationFuture;
  }

  void _retryInitialization() {
    setState(() => _future = _initializeApp());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const RunningApp();
        }

        if (snapshot.hasError) {
          return MaterialApp(
            title: 'Territory Run',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: ErrorState(
                title: 'No pudimos iniciar la app',
                message: snapshot.error.toString(),
                onRetry: _retryInitialization,
              ),
            ),
          );
        }

        // 🌀 Pantalla de carga (splash temporal)
        return MaterialApp(
          title: 'Territory Run',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        );
      },
    );
  }
}

/// 🎨 Aplicación principal con soporte de temas dinámicos y localización
class RunningApp extends ConsumerWidget {
  const RunningApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final language = ref.watch(settingsProvider.select((s) => s.language));

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: 'Territory Run',
          theme: AppTheme.light(lightDynamic),
          darkTheme: AppTheme.dark(darkDynamic),
          themeMode: switch (themeMode) {
            AppThemeMode.system => ThemeMode.system,
            AppThemeMode.light => ThemeMode.light,
            AppThemeMode.dark => ThemeMode.dark,
          },
          locale: Locale(language),
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es'),
            Locale('en'),
          ],
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return AchievementNotificationOverlay(
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
