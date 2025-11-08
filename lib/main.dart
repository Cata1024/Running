import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/env_config.dart';
import 'core/theme/app_theme.dart';
import 'presentation/navigation/app_router.dart';
import 'presentation/widgets/achievement_notification.dart';
import 'presentation/providers/app_providers.dart';
import 'core/widgets/loading_state.dart';
import 'core/widgets/error_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final baseApiUrl = EnvConfig.instance.backendApiUrl;
  if (baseApiUrl.isEmpty) {
    throw StateError('BASE_API_URL is not set in .env');
  }

  // Inicializar Firebase y otros servicios asíncronos
  await runZonedGuarded(() async {
    await initFirebase();

    // Crashlytics: registrar manejadores globales
    FlutterError.onError = (FlutterErrorDetails details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });

  await Future.wait([
    initializeDateFormatting('es'),
    initializeDateFormatting('en'),
  ]);
  await configureGoogleMaps();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: RunningApp(),
    ),
  );


  
}

/// Precarga imágenes críticas para mejorar performance inicial
Future<void> precacheAppImages(BuildContext context) async {
  try {
    await Future.wait([
      // Precachear iconos y assets críticos si existen
      // precacheImage(const AssetImage('assets/images/logo.png'), context),
      // precacheImage(const AssetImage('assets/images/splash.png'), context),
    ]);
  } catch (e) {
    debugPrint('Error precaching images: $e');
  }
}

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
          themeMode: themeMode == AppThemeMode.system
              ? ThemeMode.system
              : themeMode == AppThemeMode.light
                  ? ThemeMode.light
                  : ThemeMode.dark,
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
            return Consumer(
              builder: (context, ref, _) {
                final health = ref.watch(apiHealthProvider);
                return AchievementNotificationOverlay(
                  child: health.when(
                    data: (ok) {
                      if (ok) return child ?? const SizedBox.shrink();
                      return Center(
                        child: ErrorState(
                          message: 'No se pudo conectar con el servidor',
                          onRetry: () => ref.invalidate(apiHealthProvider),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: LoadingState(message: 'Verificando conexión...'),
                    ),
                    error: (e, st) => Center(
                      child: ErrorState(
                        message: 'Error de conexión',
                        onRetry: () => ref.invalidate(apiHealthProvider),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
