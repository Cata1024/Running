import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'features/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RunningApp());
}

class RunningApp extends StatelessWidget {
  const RunningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Territory Run',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system, // o ThemeMode.light si prefieres
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
