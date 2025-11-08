import 'dart:ui';
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/auth_method_selection_screen.dart';
import '../screens/auth/email_registration_screen.dart';
import '../screens/auth/streamlined_onboarding_screen.dart';
import '../screens/auth/profile_summary_screen.dart';
import '../screens/auth/login_improved_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/complete_profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/run/run_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/history/run_detail_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/legal/legal_consent_screen.dart';
import '../screens/achievements/achievements_screen.dart';
import '../providers/app_providers.dart';
import '../providers/run_tracker_provider.dart';
import '../../core/widgets/aero_nav_bar.dart';
import '../../core/design_system/territory_tokens.dart';
import 'custom_page_transition.dart';
import '../../core/constants/legal_constants.dart';

/// Notificador para GoRouter que reacciona a cambios de auth y perfil.
class RedirectNotifier extends ChangeNotifier {
  final Ref _ref;

  RedirectNotifier(this._ref) {
    // Escuchar cambios en el estado de autenticación y perfil
    _ref.listen(
      authStateStreamProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen(
      hasCompleteProfileProvider,
      (_, __) => notifyListeners(),
    );
  }
}

/// Router principal de la aplicación
final routerProvider = Provider<GoRouter>((ref) {
  // El notificador que escuchará los cambios para refrescar el router
  final redirectNotifier = RedirectNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: !kReleaseMode,
    refreshListenable: redirectNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateStreamProvider);
      final profileState = ref.read(hasCompleteProfileProvider);

      final isAuthLoading = authState.isLoading;
      final isProfileLoading = profileState.isLoading;

      final user = authState.asData?.value;
      final isLoggedIn = user != null;
      final hasProfile = profileState.maybeWhen(
        data: (value) => value,
        orElse: () => false,
      );

      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isPublicRoute = state.matchedLocation == '/welcome';
      final isSplash = state.matchedLocation == '/splash';
      final isLegalRoute = state.matchedLocation == '/legal-consent';

      // Mientras resolvemos estado de auth o perfil, mantener splash
      if ((isAuthLoading || (isLoggedIn && isProfileLoading)) && !isSplash) {
        return '/splash';
      }

      if (!isLoggedIn) {
        if (isSplash) {
          return '/welcome';
        }
        // Si no está logueado, solo puede acceder a las rutas públicas/auth
        return (isPublicRoute || isAuthRoute) ? null : '/welcome';
      }

      // --- Usuario Logueado ---
      final isOnboardingRoute = state.matchedLocation.startsWith('/auth/onboarding');

      if (!hasProfile) {
        // Si no tiene perfil, forzar onboarding
        return isOnboardingRoute ? null : '/auth/onboarding';
      }

      final legalConsent = ref.read(legalConsentProvider);
      final needsConsent = legalConsent.requiresRenewal(
        requiredTermsVersion: LegalConstants.termsVersion,
        requiredPrivacyVersion: LegalConstants.privacyVersion,
      );

      if (needsConsent && !isLegalRoute) {
        return '/legal-consent';
      }

      if (!needsConsent && isLegalRoute) {
        return '/map';
      }
      
      // Si tiene perfil y está en una ruta de auth/pública, redirigir al mapa
      if (isAuthRoute || isPublicRoute || isSplash) {
        return '/map';
      }

      // En cualquier otro caso, permitir el acceso
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      GoRoute(
        path: '/legal-consent',
        name: 'legal-consent',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LegalConsentScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      
      // Welcome screen (sin auth requerido)
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        pageBuilder: (context, state) => CustomPageTransition(
          key: state.pageKey,
          child: const WelcomeScreen(),
          type: PageTransitionType.fadeScale,
          duration: const Duration(milliseconds: 400),
        ).build(context, state),
      ),
      
      // Rutas de autenticación
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const LoginImprovedScreen(),
        routes: [
          // Selección de método de autenticación (NUEVO)
          GoRoute(
            path: 'method-selection',
            name: 'method-selection',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AuthMethodSelectionScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
            ),
          ),
          
          // Email + Password registration (NUEVO)
          GoRoute(
            path: 'email-registration',
            name: 'email-registration',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const EmailRegistrationScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
            ),
          ),
          
          // Onboarding simplificado (4 pasos - OPTIMIZADO)
          GoRoute(
            path: 'onboarding',
            name: 'onboarding',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const StreamlinedOnboardingScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
          
          // Resumen del perfil (NUEVO)
          GoRoute(
            path: 'profile-summary',
            name: 'profile-summary',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProfileSummaryScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
            ),
          ),
          
          // Login
          GoRoute(
            path: 'login',
            name: 'login',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const LoginImprovedScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
            ),
          ),
          
          // Forgot password
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
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            builder: (context, state) => const HistoryScreen(),
            routes: [
              GoRoute(
                path: 'detail',
                name: 'run-detail',
                pageBuilder: (context, state) {
                  final id = state.extra as String?;
                  if (id == null) {
                    return MaterialPage(
                      key: state.pageKey,
                      child: ErrorScreen(error: Exception('Run id missing')),
                    );
                  }
                  return CustomPageTransition(
                    key: state.pageKey,
                    child: RunDetailScreen(runId: id),
                    type: PageTransitionType.sharedAxis,
                    duration: const Duration(milliseconds: 350),
                  ).build(context, state);
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
                pageBuilder: (context, state) => CustomPageTransition(
                  key: state.pageKey,
                  child: const CompleteProfileScreen(),
                  type: PageTransitionType.slideUp,
                  duration: const Duration(milliseconds: 350),
                ).build(context, state),
              ),
              GoRoute(
                path: 'edit',
                name: 'edit-profile',
                pageBuilder: (context, state) => CustomPageTransition(
                  key: state.pageKey,
                  child: const EditProfileScreen(),
                  type: PageTransitionType.slideLeft,
                  duration: const Duration(milliseconds: 300),
                ).build(context, state),
              ),
            ],
          ),
        ],
      ),
      // Ajustes fuera del shell; se accede desde Perfil
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => CustomPageTransition(
          key: state.pageKey,
          child: const SettingsScreen(),
          type: PageTransitionType.slideLeft,
          duration: const Duration(milliseconds: 300),
        ).build(context, state),
      ),
      // Logros fuera del shell; se accede desde Perfil
      GoRoute(
        path: '/achievements',
        name: 'achievements',
        pageBuilder: (context, state) => CustomPageTransition(
          key: state.pageKey,
          child: const AchievementsScreen(),
          type: PageTransitionType.slideUp,
          duration: const Duration(milliseconds: 350),
        ).build(context, state),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: ErrorScreen(error: state.error),
    ),
  );
});

/// Shell principal de la aplicación con navegación
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const List<AeroNavBarItem> _navItems = [
    AeroNavBarItem(icon: Icons.map_outlined, label: 'Mapa'),
    AeroNavBarItem(icon: Icons.history_outlined, label: 'Historial'),
    AeroNavBarItem(icon: Icons.person_outline, label: 'Perfil'),
  ];

  late final Widget _persistentMap = RunScreen(
    onRunStateChanged: null,
  );

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final runStatus = ref.watch(
      runTrackerProvider.select((state) => (state.isRunning, state.isPaused)),
    );
    int currentIndex = 0;

    if (currentPath.startsWith('/history')) {
      currentIndex = 1;
    } else if (currentPath.startsWith('/profile')) {
      currentIndex = 2;
    }

    final bool onRunScreen = currentPath.startsWith('/map');
    final bool navBarVisible = !(onRunScreen && runStatus.$1 && !runStatus.$2);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: _persistentMap),
          if (!onRunScreen)
            Positioned.fill(
              child: _BlurredOverlay(child: widget.child),
            ),
          _MeasuredNavBar(
            visible: navBarVisible,
            currentIndex: currentIndex,
            onItemSelected: (index) {
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
          ),
        ],
      ),
    );
  }
}

class _MeasuredNavBar extends ConsumerStatefulWidget {
  final bool visible;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const _MeasuredNavBar({
    required this.visible,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  ConsumerState<_MeasuredNavBar> createState() => _MeasuredNavBarState();
}

class _MeasuredNavBarState extends ConsumerState<_MeasuredNavBar> {
  @override
  void initState() {
    super.initState();
    _notifyNavBarHeight();
  }

  @override
  void didUpdateWidget(covariant _MeasuredNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _notifyNavBarHeight();
  }

  void _notifyNavBarHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final height = widget.visible ? AeroNavBar.preferredHeight : 0.0;
      ref.read(navBarHeightProvider.notifier).setHeight(height);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AeroNavBar(
      items: _AppShellState._navItems,
      currentIndex: widget.currentIndex,
      visible: widget.visible,
      onItemSelected: widget.onItemSelected,
    );
  }
}

class _BlurredOverlay extends StatelessWidget {
  final Widget child;

  const _BlurredOverlay({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color veilColor = scheme.surface.withValues(alpha: 0.78);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: TerritoryTokens.blurStrong,
          sigmaY: TerritoryTokens.blurStrong,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: veilColor),
          child: child,
        ),
      ),
    );
  }
}

/// Pantalla de splash
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary,
              scheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(TerritoryTokens.radiusXLarge),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(36),
                  child: SvgPicture.asset(
                    'assets/icons/running.svg',
                    width: 120,
                    height: 120,
                    colorFilter: ColorFilter.mode(scheme.onPrimary, BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Territory Run',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 32),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(scheme.onPrimary),
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
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
