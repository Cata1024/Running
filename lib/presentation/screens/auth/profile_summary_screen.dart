import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_widgets.dart';
import '../../../domain/entities/registration_data.dart';
import '../../../presentation/providers/app_providers.dart';
import 'complete_onboarding_screen.dart';

/// Pantalla de resumen del perfil antes de confirmar el registro
/// 
/// Muestra todos los datos recopilados y permite confirmar o editar
class ProfileSummaryScreen extends ConsumerStatefulWidget {
  const ProfileSummaryScreen({super.key});

  @override
  ConsumerState<ProfileSummaryScreen> createState() => _ProfileSummaryScreenState();
}

class _ProfileSummaryScreenState extends ConsumerState<ProfileSummaryScreen> {
  bool _isLoading = false;

  Future<void> _confirmRegistration() async {
    final onboardingData = ref.read(onboardingDataProvider);
    
    // Validar que todos los datos estén completos
    if (onboardingData.displayName.isEmpty) {
      _showError('Falta el nombre');
      return;
    }
    if (onboardingData.birthDate == null) {
      _showError('Falta la fecha de nacimiento');
      return;
    }
    if (onboardingData.gender.isEmpty) {
      _showError('Falta seleccionar el género');
      return;
    }
    if (onboardingData.goalType.isEmpty) {
      _showError('Falta seleccionar el objetivo');
      return;
    }
    
    // Validar email/password solo si es registro con email
    final authMethod = onboardingData.authMethod ?? AuthMethod.emailPassword;
    if (authMethod == AuthMethod.emailPassword) {
      if (onboardingData.email == null || onboardingData.email!.isEmpty) {
        _showError('Falta el email. Por favor regresa y completa tus credenciales.');
        return;
      }
      if (onboardingData.password == null || onboardingData.password!.isEmpty) {
        _showError('Falta la contraseña. Por favor regresa y completa tus credenciales.');
        return;
      }
    }
    
    // Para Google/Apple/Facebook, el email puede venir del provider
    String? emailToUse = onboardingData.email;
    if (authMethod == AuthMethod.google) {
      // Si no tiene email guardado, obtener del usuario autenticado actual
      final currentUser = ref.read(authServiceProvider).currentUser;
      if (currentUser != null && currentUser.email != null) {
        emailToUse = currentUser.email;
      }
    }
    
    // Crear RegistrationData
    final registrationData = RegistrationData(
      email: emailToUse,
      password: onboardingData.password,
      displayName: onboardingData.displayName,
      birthDate: onboardingData.birthDate!,
      gender: onboardingData.gender,
      weightKg: onboardingData.weightKg,
      heightCm: onboardingData.heightCm,
      goalType: onboardingData.goalType,
      weeklyDistanceGoal: onboardingData.weeklyDistanceGoal,
      goalDescription: onboardingData.goalDescription,
      preferredUnits: onboardingData.preferredUnits,
      authMethod: authMethod,
    );
    
    // Validar con mensajes específicos
    if (!registrationData.isValid) {
      if (authMethod == AuthMethod.emailPassword && 
          (registrationData.email == null || registrationData.email!.isEmpty)) {
        _showError('Email requerido. Por favor vuelve y completa el formulario de registro.');
      } else if (registrationData.displayName.trim().isEmpty) {
        _showError('El nombre no puede estar vacío');
      } else if (registrationData.weightKg <= 0 || registrationData.weightKg > 500) {
        _showError('El peso debe estar entre 1 y 500 kg');
      } else if (registrationData.heightCm <= 0 || registrationData.heightCm > 300) {
        _showError('La altura debe estar entre 1 y 300 cm');
      } else if (registrationData.weeklyDistanceGoal < 0) {
        _showError('La meta semanal debe ser positiva');
      } else {
        _showError('Algunos datos no son válidos. Por favor revisa.');
      }
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Registrar con datos completos
      final authService = ref.read(authServiceProvider);
      await authService.registerWithCompleteData(registrationData);
      
      if (!mounted) return;
      
      // Limpiar datos del onboarding
      ref.read(onboardingDataProvider.notifier).reset();
      
      // El router redirigirá automáticamente a /map cuando detecte el cambio de auth
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Cuenta creada con éxito! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Error al crear la cuenta: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
        ),
      ),
    );
  }

  void _editData() {
    // Regresar al onboarding manteniendo los datos
    context.go('/auth/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = ref.watch(onboardingDataProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Perfil'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header con icono
                  _buildHeader(theme, data),
                  
                  const SizedBox(height: 32),
                  
                  // Sección: Datos Personales
                  _buildSection(
                    theme,
                    'Datos Personales',
                    Icons.person_outline,
                    [
                      if (data.email != null && data.email!.isNotEmpty)
                        _buildDataRow(
                          theme,
                          'Email',
                          data.email!,
                          Icons.email_outlined,
                        ),
                      _buildDataRow(
                        theme,
                        'Nombre',
                        data.displayName,
                        Icons.badge_outlined,
                      ),
                      _buildDataRow(
                        theme,
                        'Edad',
                        '${_calculateAge(data.birthDate)} años',
                        Icons.cake_outlined,
                      ),
                      _buildDataRow(
                        theme,
                        'Género',
                        _getGenderLabel(data.gender),
                        Icons.people_outline,
                      ),
                      if (data.authMethod != null)
                        _buildDataRow(
                          theme,
                          'Método de registro',
                          _getAuthMethodLabel(data.authMethod!),
                          Icons.verified_user_outlined,
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sección: Datos Físicos
                  _buildSection(
                    theme,
                    'Datos Físicos',
                    Icons.fitness_center,
                    [
                      _buildDataRow(
                        theme,
                        'Peso',
                        '${data.weightKg.toStringAsFixed(1)} kg',
                        Icons.monitor_weight_outlined,
                      ),
                      _buildDataRow(
                        theme,
                        'Altura',
                        '${data.heightCm} cm',
                        Icons.height,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sección: Objetivos
                  _buildSection(
                    theme,
                    'Objetivos',
                    Icons.flag_outlined,
                    [
                      _buildDataRow(
                        theme,
                        'Objetivo',
                        _getGoalLabel(data.goalType),
                        Icons.emoji_events_outlined,
                      ),
                      _buildDataRow(
                        theme,
                        'Meta Semanal',
                        '${data.weeklyDistanceGoal.toStringAsFixed(0)} km',
                        Icons.directions_run,
                      ),
                      _buildDataRow(
                        theme,
                        'Unidades',
                        data.preferredUnits == 'metric' ? 'Métricas (km)' : 'Imperiales (mi)',
                        Icons.straighten,
                      ),
                      if (data.goalDescription != null && data.goalDescription!.isNotEmpty)
                        _buildDataRow(
                          theme,
                          'Descripción',
                          data.goalDescription!,
                          Icons.description_outlined,
                          maxLines: 3,
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Botones de acción
                  AeroButton(
                    onPressed: _isLoading ? null : _confirmRegistration,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirmar y Crear Cuenta'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _editData,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar Datos'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme, OnboardingData data) {
    return Column(
      children: [
        // Avatar grande
        Container(
          width: 100,
          height: 100,
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
          child: Center(
            child: Text(
              _getInitials(data.displayName),
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          '¡Hola, ${data.displayName.split(' ').first}!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Revisa tu información antes de continuar',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSection(
    ThemeData theme,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AeroCard(
          enableBlur: false,
          level: AeroLevel.ghost,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: children
                  .expand((widget) => [widget, const SizedBox(height: 16)])
                  .toList()
                ..removeLast(), // Eliminar último SizedBox
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.iconTheme.color?.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _getGenderLabel(String gender) {
    switch (gender) {
      case 'male':
        return 'Masculino';
      case 'female':
        return 'Femenino';
      case 'other':
        return 'Otro';
      case 'prefer_not_say':
        return 'Prefiero no decir';
      default:
        return gender;
    }
  }

  String _getAuthMethodLabel(AuthMethod method) {
    switch (method) {
      case AuthMethod.emailPassword:
        return 'Email y contraseña';
      case AuthMethod.google:
        return 'Google';
      case AuthMethod.apple:
        return 'Apple';
      case AuthMethod.facebook:
        return 'Facebook';
    }
  }

  String _getGoalLabel(String goalType) {
    switch (goalType) {
      case 'fitness':
        return 'Fitness General';
      case 'weight_loss':
        return 'Perder Peso';
      case 'competition':
        return 'Competir';
      case 'fun':
        return 'Diversión';
      default:
        return goalType;
    }
  }
}
