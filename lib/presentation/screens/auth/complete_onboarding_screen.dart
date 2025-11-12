import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_widgets.dart';
import '../../../domain/entities/registration_data.dart';
import 'onboarding_steps_continuation.dart';

/// Datos temporales del onboarding
class OnboardingData {
  String displayName = '';
  DateTime? birthDate;
  String gender = '';
  double weightKg = 70.0;
  int heightCm = 170;
  String goalType = '';
  double weeklyDistanceGoal = 20.0;
  String? goalDescription;
  String preferredUnits = 'metric';
  AuthMethod? authMethod;
  bool completedOnboarding = false;
  
  // Para email/password
  String? email;
  String? password;
}

/// Notifier simple para OnboardingData
class OnboardingDataNotifier extends Notifier<OnboardingData> {
  @override
  OnboardingData build() => OnboardingData();
  
  void updateField(void Function(OnboardingData data) updater) {
    // Crear una copia del estado actual para evitar mutación directa
    final newData = OnboardingData()
      ..displayName = state.displayName
      ..birthDate = state.birthDate
      ..gender = state.gender
      ..weightKg = state.weightKg
      ..heightCm = state.heightCm
      ..goalType = state.goalType
      ..weeklyDistanceGoal = state.weeklyDistanceGoal
      ..goalDescription = state.goalDescription
      ..preferredUnits = state.preferredUnits
      ..completedOnboarding = state.completedOnboarding
      ..email = state.email
      ..password = state.password
      ..authMethod = state.authMethod;
    
    // Aplicar los cambios a la copia
    updater(newData);
    
    // Asignar la nueva instancia al estado
    state = newData;
  }
  
  void reset() {
    state = OnboardingData();
  }
}

/// Provider para almacenar temporalmente los datos del onboarding
final onboardingDataProvider = NotifierProvider<OnboardingDataNotifier, OnboardingData>(
  () => OnboardingDataNotifier(),
);

/// Pantalla completa de onboarding con 8 pasos
/// 
/// Recopila TODOS los datos necesarios para el perfil del usuario
class CompleteOnboardingScreen extends ConsumerStatefulWidget {
  final AuthMethod? authMethod;
  
  const CompleteOnboardingScreen({
    super.key,
    this.authMethod,
  });

  @override
  ConsumerState<CompleteOnboardingScreen> createState() => _CompleteOnboardingScreenState();
}

class _CompleteOnboardingScreenState extends ConsumerState<CompleteOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  int _totalSteps = 8;
  bool _needsEmailPassword = false;

  @override
  void initState() {
    super.initState();
    // Guardar authMethod si viene como parámetro
    if (widget.authMethod != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(onboardingDataProvider.notifier).updateField((data) {
          data.authMethod = widget.authMethod;
        });
      });
    }
    
    // Verificar si necesita ingresar email/password
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ref.read(onboardingDataProvider);
      final authMethod = data.authMethod ?? AuthMethod.emailPassword;
      
      if (authMethod == AuthMethod.emailPassword && 
          (data.email == null || data.email!.isEmpty)) {
        setState(() {
          _needsEmailPassword = true;
          _totalSteps = 9; // 1 paso extra para email/password
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    // Haptic feedback
    HapticFeedback.selectionClick();
    
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _completeOnboarding() {
    final data = ref.read(onboardingDataProvider);
    
    // Validar que todos los datos requeridos estén completos
    if (data.displayName.isEmpty ||
        data.birthDate == null ||
        data.gender.isEmpty ||
        data.goalType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los datos')),
      );
      return;
    }
    
    // Navegar a la pantalla de resumen
    context.go('/auth/profile-summary');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            _buildProgressBar(theme),
            
            // Content
            Expanded(
              child: PageView(
                key: ValueKey('pageview_$_needsEmailPassword'),
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentStep = page),
                children: [
                  // Paso 0 (opcional): Email y Password
                  if (_needsEmailPassword)
                    _StepEmailPassword(
                      key: const ValueKey('step_email_password'),
                      onNext: _nextStep,
                    ),
                  // Pasos regulares
                  _StepWelcomeAndName(
                    key: const ValueKey('step_welcome'),
                    onNext: _nextStep,
                    onBack: _needsEmailPassword ? _previousStep : null,
                  ),
                  _StepBirthDate(
                    key: const ValueKey('step_birthdate'),
                    onNext: _nextStep,
                    onBack: _previousStep,
                  ),
                  _StepGender(
                    key: const ValueKey('step_gender'),
                    onNext: _nextStep,
                    onBack: _previousStep,
                  ),
                  StepWeight(
                    key: const ValueKey('step_weight'),
                    onNext: _nextStep,
                    onBack: _previousStep,
                  ),
                  StepHeight(
                    key: const ValueKey('step_height'),
                    onNext: _nextStep,
                    onBack: _previousStep,
                  ),
                  StepGoal(
                    key: const ValueKey('step_goal'),
                    onNext: _nextStep,
                    onBack: _previousStep,
                  ),
                  StepWeeklyGoal(
                    key: const ValueKey('step_weekly_goal'),
                    onNext: _nextStep,
                    onBack: _previousStep,
                  ),
                  StepDescription(
                    key: const ValueKey('step_description'),
                    onNext: _nextStep,
                    onBack: _previousStep,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    final progress = (_currentStep + 1) / _totalSteps;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _currentStep > 0 ? _previousStep : () => context.pop(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paso ${_currentStep + 1} de $_totalSteps',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
      ],
    );
  }
}

// ==================== PASO 0 (Opcional): Email y Password ====================

class _StepEmailPassword extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  
  const _StepEmailPassword({super.key, required this.onNext});

  @override
  ConsumerState<_StepEmailPassword> createState() => _StepEmailPasswordState();
}

class _StepEmailPasswordState extends ConsumerState<_StepEmailPassword> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Diferir la lectura del provider hasta después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final data = ref.read(onboardingDataProvider);
      _emailController.text = data.email ?? '';
      _passwordController.text = data.password ?? '';
      _confirmPasswordController.text = data.password ?? '';
    });
    
    // Animaciones
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _animationController.forward();
    
    // Autofocus después de la animación
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _emailFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_formKey.currentState?.validate() ?? false) {
      HapticFeedback.mediumImpact();
      // Diferir la modificación del provider hasta después del frame actual
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(onboardingDataProvider.notifier).updateField((data) {
          data.email = _emailController.text.trim();
          data.password = _passwordController.text;
        });
        widget.onNext();
      });
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 32),
                
                // Icono
                Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.email_outlined, size: 60, color: Colors.white),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'Crea tu cuenta',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Ingresa tu email y contraseña para continuar',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // Email
            AeroTextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              label: 'Email',
              hint: 'tu@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passwordFocusNode.requestFocus(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Password
            AeroTextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: 'Contraseña',
              hint: 'Mínimo 6 caracteres',
              prefixIcon: const Icon(Icons.lock_outline),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa una contraseña';
                }
                if (value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Confirm Password
            AeroTextField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              label: 'Confirmar contraseña',
              hint: 'Repite tu contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleNext(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor confirma tu contraseña';
                }
                if (value != _passwordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 48),
            
            // Continue button
            AeroButton(
              onPressed: _handleNext,
              child: const Text('Continuar'),
            ),
            
            const SizedBox(height: 16),
            
            // Terms
            Text(
              'Al continuar, aceptas nuestros Términos de Servicio y Política de Privacidad',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

// ==================== PASO 1: Bienvenida + Nombre ====================

class _StepWelcomeAndName extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  
  const _StepWelcomeAndName({super.key, required this.onNext, this.onBack});

  @override
  ConsumerState<_StepWelcomeAndName> createState() => _StepWelcomeAndNameState();
}

class _StepWelcomeAndNameState extends ConsumerState<_StepWelcomeAndName> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Diferir la lectura del provider hasta después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _nameController.text = ref.read(onboardingDataProvider).displayName;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleNext() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu nombre')),
      );
      return;
    }
    
    // Diferir la modificación del provider hasta después del frame actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingDataProvider.notifier).updateField((data) {
        data.displayName = name;
      });
      widget.onNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          
          // Hero illustration
          Hero(
            tag: 'onboarding_hero',
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.waving_hand, size: 60, color: Colors.white),
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            '¡Bienvenido a Territory Run!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Cuéntanos un poco sobre ti para personalizar tu experiencia',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          AeroTextField(
            controller: _nameController,
            label: '¿Cómo te llamas?',
            hint: 'Tu nombre completo',
            prefixIcon: const Icon(Icons.person_outline),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _handleNext(),
          ),
          
          const SizedBox(height: 32),
          
          AeroButton(
            onPressed: _handleNext,
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}

// ==================== PASO 2: Fecha de Nacimiento ====================

class _StepBirthDate extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const _StepBirthDate({super.key, required this.onNext, required this.onBack});

  @override
  ConsumerState<_StepBirthDate> createState() => _StepBirthDateState();
}

class _StepBirthDateState extends ConsumerState<_StepBirthDate> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Diferir la lectura del provider hasta después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedDate = ref.read(onboardingDataProvider).birthDate;
      });
    });
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final minDate = DateTime(now.year - 100);
    final maxDate = DateTime(now.year - 13); // Mínimo 13 años
    
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? maxDate,
      firstDate: minDate,
      lastDate: maxDate,
    );
    
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _handleNext() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona tu fecha de nacimiento')),
      );
      return;
    }
    
    // Diferir la modificación del provider hasta después del frame actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingDataProvider.notifier).updateField((data) {
        data.birthDate = _selectedDate;
      });
      widget.onNext();
    });
  }

  int? get _age {
    if (_selectedDate == null) return null;
    final now = DateTime.now();
    var age = now.year - _selectedDate!.year;
    if (now.month < _selectedDate!.month ||
        (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          
          Icon(
            Icons.cake_outlined,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            '¿Cuándo naciste?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Esto nos ayuda a personalizar tu experiencia',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          AeroCard(
            onTap: _selectDate,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'Selecciona tu fecha'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_age != null)
                          Text(
                            '$_age años',
                            style: theme.textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          AeroButton(
            onPressed: _handleNext,
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}

// ==================== PASO 3: Género ====================

class _StepGender extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const _StepGender({super.key, required this.onNext, required this.onBack});

  void _selectGender(BuildContext context, WidgetRef ref, String gender) {
    // Diferir la modificación del provider hasta después del frame actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingDataProvider.notifier).updateField((data) {
        data.gender = gender;
      });
      onNext();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedGender = ref.watch(onboardingDataProvider).gender;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          
          Icon(
            Icons.people_outline,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Cuéntanos sobre ti',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Esto nos ayuda a darte mejores recomendaciones',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          _GenderOption(
            icon: Icons.male,
            label: 'Masculino',
            value: 'male',
            isSelected: selectedGender == 'male',
            onTap: () => _selectGender(context, ref, 'male'),
          ),
          
          const SizedBox(height: 16),
          
          _GenderOption(
            icon: Icons.female,
            label: 'Femenino',
            value: 'female',
            isSelected: selectedGender == 'female',
            onTap: () => _selectGender(context, ref, 'female'),
          ),
          
          const SizedBox(height: 16),
          
          _GenderOption(
            icon: Icons.more_horiz,
            label: 'Otro',
            value: 'other',
            isSelected: selectedGender == 'other',
            onTap: () => _selectGender(context, ref, 'other'),
          ),
          
          const SizedBox(height: 16),
          
          _GenderOption(
            icon: Icons.lock_outline,
            label: 'Prefiero no decir',
            value: 'prefer_not_say',
            isSelected: selectedGender == 'prefer_not_say',
            onTap: () => _selectGender(context, ref, 'prefer_not_say'),
          ),
        ],
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AeroCard(
      level: isSelected ? AeroLevel.medium : AeroLevel.ghost,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: isSelected
            ? BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
              )
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.iconTheme.color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

// Continuará en el siguiente mensaje debido a límites de longitud...
