import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../shared/services.dart';
import 'auth/widgets/auth_background.dart';
import 'auth/widgets/auth_form.dart';
import 'auth/widgets/auth_header.dart';
import 'home.dart';

/// Pantalla de autenticación principal
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      if (_isLogin) {
        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        final credential = await authService.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (credential?.user != null) {
          final user = UserModel(
            id: credential!.user!.uid,
            email: _emailController.text.trim(),
            displayName: credential.user!.email?.split('@').first ?? 'Runner',
            createdAt: DateTime.now(),
          );

          await firestoreService.saveUserProfile(user);
        }
      }
    } on FirebaseAuthException catch (e) {
      var message = 'Error de autenticación';

      switch (e.code) {
        case 'user-not-found':
          message = 'Usuario no encontrado';
          break;
        case 'wrong-password':
          message = 'Contraseña incorrecta';
          break;
        case 'email-already-in-use':
          message = 'El email ya está en uso';
          break;
        case 'weak-password':
          message = 'La contraseña es muy débil';
          break;
        case 'invalid-email':
          message = 'Email inválido';
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error inesperado')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      final credential = await authService.signInWithGoogle();
      final user = credential?.user;

      if (user == null) {
        return;
      }

      final profile = await firestoreService.getUserProfile(user.uid);
      if (profile == null) {
        final newUser = UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName:
              user.displayName ?? user.email?.split('@').first ?? 'Runner',
          createdAt: DateTime.now(),
          photoUrl: user.photoURL,
        );
        await firestoreService.saveUserProfile(newUser);
      }
    } on FirebaseAuthException catch (e) {
      var message = 'Error de autenticación con Google';

      switch (e.code) {
        case 'account-exists-with-different-credential':
          message = 'Ya existe una cuenta con otro método de acceso.';
          break;
        case 'invalid-credential':
          message = 'Credenciales de Google inválidas.';
          break;
        case 'operation-not-allowed':
          message = 'El acceso con Google no está habilitado.';
          break;
        case 'user-disabled':
          message = 'La cuenta de Google está deshabilitada.';
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo completar el acceso con Google.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AuthHeader(isLogin: _isLogin),
                    const SizedBox(height: 48),
                    AuthForm(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      isLogin: _isLogin,
                      isLoading: _isLoading,
                      isGoogleLoading: _isGoogleLoading,
                      onSubmit: _handleAuth,
                      onToggleMode: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _formKey.currentState?.reset();
                        });
                      },
                      onGoogleSignIn: _handleGoogleSignIn,
                      onForgotPassword: _showResetPasswordDialog,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showResetPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Ingresa tu email para recibir un enlace de restablecimiento'),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.trim().isNotEmpty) {
                try {
                  await ref
                      .read(authServiceProvider)
                      .resetPassword(emailController.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Email enviado. Revisa tu bandeja de entrada.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error enviando email')),
                    );
                  }
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}

/// Wrapper para manejar el estado de autenticación
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // Usuario logueado - ir a HomePage existente
          return const HomePage();
        } else {
          // Usuario no logueado - mostrar AuthScreen
          return const AuthScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(authStateProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
