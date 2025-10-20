import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/complete_profile_screen.dart';
import '../screens/run/run_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/history/run_detail_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../providers/app_providers.dart';

/// Router principal de la aplicación
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateStreamProvider);
  
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authState.when(
        data: (user) => user != null,
        loading: () => false,
        error: (_, __) => false,
      );
      
      final isLoggingIn = state.matchedLocation.startsWith('/auth');
      final isRoot = state.matchedLocation == '/';

      // Si está en la raíz, redirigir según estado de auth
      if (isRoot) {
        return isLoggedIn ? '/map' : '/auth/login';
      }

      // Si no está logueado y no está en auth, redirigir a login
      if (!isLoggedIn && !isLoggingIn) {
        return '/auth/login';
      }

      // Si está logueado y está en auth, redirigir a home
      if (isLoggedIn && isLoggingIn) {
        return '/map';
      }

      return null;
    },
    routes: [
      // Ruta raíz - redirige automáticamente
      GoRoute(
        path: '/',
        redirect: (context, state) => '/auth/login',
      ),
      
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Rutas de autenticación
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: 'register',
            name: 'register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: 'forgot-password',
            name: 'forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
        ],
      ),

      // Rutas principales con shell para navegación persistente
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Pestaña 1: Mapa (tracking)
          GoRoute(
            path: '/map',
            name: 'map',
            builder: (context, state) => const RunScreen(),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            builder: (context, state) => const HistoryScreen(),
            routes: [
              GoRoute(
                path: 'detail',
                name: 'run-detail',
                builder: (context, state) {
                  final id = state.extra as String?;
                  if (id == null) {
                    return ErrorScreen(error: Exception('Run id missing'));
                  }
                  return RunDetailScreen(runId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'complete',
                name: 'complete-profile',
                builder: (context, state) => const CompleteProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Ajustes fuera del shell; se accede desde Perfil
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: ErrorScreen(error: state.error),
    ),
  );
});

/// Shell principal de la aplicación con navegación
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    
    if (currentPath.startsWith('/history')) {
      currentIndex = 1;
    } else if (currentPath.startsWith('/profile')) {
      currentIndex = 2;
    }
    
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/map');
              break;
            case 1:
              context.go('/history');
              break;
            case 2:
              context.go('/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

/// Pantalla de splash
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_run,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'Territory Run',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pantalla de error
class ErrorScreen extends StatelessWidget {
  final Exception? error;

  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Algo salió mal',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Error desconocido',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stream para refrescar el router con cambios de autenticación
