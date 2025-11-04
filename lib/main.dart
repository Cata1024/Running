import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'core/env_config.dart';
import 'core/theme/app_theme.dart';
import 'presentation/navigation/app_router.dart';
import 'presentation/widgets/achievement_notification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final baseApiUrl = EnvConfig.instance.backendApiUrl;
  if (baseApiUrl.isEmpty) {
    throw StateError('BASE_API_URL is not set in .env');
  }

  // Inicializar Firebase
  try {
    await initFirebase();
  } on UnsupportedError {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

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

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: 'Territory Run',
          theme: AppTheme.light(lightDynamic),
          darkTheme: AppTheme.dark(darkDynamic),
          themeMode: ThemeMode.system,
          routerConfig: router,
          localizationsDelegates: const [
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
