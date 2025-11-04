import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    const ProviderScope(
      child: DiagnosticApp(),
    ),
  );
}

class DiagnosticApp extends StatelessWidget {
  const DiagnosticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diagnostic Mode',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const DiagnosticScreen(),
    );
  }
}

class DiagnosticScreen extends ConsumerWidget {
  const DiagnosticScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Mode'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'App funcionando en modo diagnóstico',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                debugPrint('✅ Botón presionado - App funcionando correctamente');
              },
              child: const Text('Test Button'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Si ves esta pantalla, el problema está en algún provider específico.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
