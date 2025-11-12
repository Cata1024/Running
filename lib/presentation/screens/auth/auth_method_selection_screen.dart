import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../domain/entities/registration_data.dart';
import '../../providers/app_providers.dart';
import 'complete_onboarding_screen.dart';

/// Pantalla para seleccionar método de autenticación
/// 
/// El usuario elige cómo quiere registrarse antes del onboarding
class AuthMethodSelectionScreen extends ConsumerStatefulWidget {
  const AuthMethodSelectionScreen({super.key});

  @override
  ConsumerState<AuthMethodSelectionScreen> createState() => _AuthMethodSelectionScreenState();
}

class _AuthMethodSelectionScreenState extends ConsumerState<AuthMethodSelectionScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1a1a1a),
                        const Color(0xFF0a0a0a),
                      ]
                    : [
                        const Color(0xFFFAFAFA),
                        const Color(0xFFE8E8E8),
                      ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      children: [
                        // Header con ilustración
                        _buildHeader(theme),
                        
                        const SizedBox(height: 48),
                        
                        // Métodos de autenticación
                        _buildAuthMethods(theme),
                        
                        const SizedBox(height: 32),
                        
                        // Link a login
                        _buildLoginLink(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Indicador de carga
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        // Ilustración hero
        Hero(
          tag: 'auth_logo',
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          '¡Comencemos!',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Elige cómo quieres registrarte',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAuthMethods(ThemeData theme) {
    return Column(
      children: [
        // Google
        _AuthMethodCard(
          title: 'Continuar con Google',
          icon: SvgPicture.asset(
            'assets/icons/google-icon-logo-svgrepo-com.svg',
            width: 28,
            height: 28,
          ),
          gradient: const LinearGradient(
            colors: [Color(0xFF4285F4), Color(0xFF357AE8)],
          ),
          onTap: () => _handleGoogleSignIn(),
        ),
        
        const SizedBox(height: 16),
        
        // Apple (próximamente)
        _AuthMethodCard(
          title: 'Continuar con Apple',
          icon: const Icon(Icons.apple, size: 28, color: Colors.white),
          gradient: LinearGradient(
            colors: [Colors.grey.shade800, Colors.black],
          ),
          isDisabled: true,
          onTap: () => _showComingSoon('Apple'),
        ),
        
        const SizedBox(height: 16),
        
        // Facebook (próximamente)
        _AuthMethodCard(
          title: 'Continuar con Facebook',
          icon: const Icon(Icons.facebook, size: 28, color: Colors.white),
          gradient: const LinearGradient(
            colors: [Color(0xFF1877F2), Color(0xFF0E58CA)],
          ),
          isDisabled: true,
          onTap: () => _showComingSoon('Facebook'),
        ),
        
        const SizedBox(height: 24),
        
        // Divider con "o"
        Row(
          children: [
            Expanded(child: Divider(color: theme.dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'o',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                ),
              ),
            ),
            Expanded(child: Divider(color: theme.dividerColor)),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Email/Password
        _AuthMethodCard(
          title: 'Continuar con Email',
          icon: const Icon(Icons.email_outlined, size: 28, color: Colors.white),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
          onTap: () => _handleEmailPasswordSelection(),
        ),
      ],
    );
  }

  Widget _buildLoginLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes cuenta? ',
          style: theme.textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () => context.go('/auth/login'),
          child: Text(
            'Inicia Sesión',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// Maneja el inicio de sesión con Google
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      // Autenticar con Google primero
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithGoogle();
      
      if (!mounted) return;
      
      // Limpiar datos previos para evitar residuos
      ref.read(onboardingDataProvider.notifier).reset();

      // Guardar el método de autenticación
      ref.read(onboardingDataProvider.notifier).updateField((data) {
        data.authMethod = AuthMethod.google;
        data.email = user.email; // Guardar el email de Google
      });
      
      // Navegar al onboarding para completar el perfil
      if (mounted) {
        context.go('/auth/onboarding');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar sesión con Google: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
          ),
        ),
      );
    }
  }

  /// Maneja la selección de Email/Password
  void _handleEmailPasswordSelection() {
    // Diferir la modificación del provider hasta después del frame actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingDataProvider.notifier).reset();
      ref.read(onboardingDataProvider.notifier).updateField((data) {
        data.authMethod = AuthMethod.emailPassword;
      });
      
      // Ir a la pantalla de registro con email
      context.go('/auth/email-registration');
    });
  }

  void _showComingSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider estará disponible próximamente'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
        ),
      ),
    );
  }
}

/// Card para un método de autenticación
class _AuthMethodCard extends StatelessWidget {
  final String title;
  final Widget icon;
  final Gradient gradient;
  final VoidCallback onTap;
  final bool isDisabled;

  const _AuthMethodCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isDisabled ? null : gradient,
            color: isDisabled ? theme.disabledColor.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            child: Row(
              children: [
                // Icono
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
                  ),
                  child: Center(child: icon),
                ),
                
                const SizedBox(width: 16),
                
                // Título
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDisabled ? theme.disabledColor : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                // Flecha o "Próximamente"
                if (isDisabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
                    ),
                    child: Text(
                      'Próximamente',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.disabledColor,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
