import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/env_config.dart';
import 'core/theme.dart';
import 'features/root_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initFirebase();
  await configureGoogleMaps();

  runApp(
    const ProviderScope(
      child: RunningApp(),
    ),
  );
}

class RunningApp extends StatelessWidget {
  const RunningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightScheme = lightDynamic?.harmonized();
        final darkScheme = darkDynamic?.harmonized();

        return MaterialApp(
          title: 'Territory Run',
          theme: AppTheme.light(lightScheme),
          darkTheme: AppTheme.dark(darkScheme),
          themeMode: ThemeMode.system,
          home: const RootShell(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
