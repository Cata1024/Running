import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_widgets.dart';
import '../../../domain/entities/registration_data.dart';
import 'complete_onboarding_screen.dart';
import 'streamlined_onboarding_steps_final.dart' as final_steps;

/// Onboarding simplificado de 4 pasos
/// Reducido desde 8-9 pasos para mejorar conversión
class StreamlinedOnboardingScreen extends ConsumerStatefulWidget {
  final AuthMethod? authMethod;

  const StreamlinedOnboardingScreen({
    super.key,
    this.authMethod,
  });

  @override
  ConsumerState<StreamlinedOnboardingScreen> createState() =>
      _StreamlinedOnboardingScreenState();
}

class _StreamlinedOnboardingScreenState
    extends ConsumerState<StreamlinedOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 4;

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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.lightImpact();

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    HapticFeedback.selectionClick();

    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _completeOnboarding() {
    final data = ref.read(onboardingDataProvider);

    // Validar datos esenciales
    if (data.displayName.isEmpty ||
        data.birthDate == null ||
        data.gender.isEmpty ||
        data.goalType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los datos'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    ref.read(onboardingDataProvider.notifier).updateField((mutable) {
      mutable.completedOnboarding = true;
    });

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
            // Progress bar mejorado
            _buildProgressBar(theme),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentStep = page),
                children: [
                  _Step1WelcomeAndBasics(onNext: _nextStep),
                  _Step2PhysicalProfile(onNext: _nextStep),
                  final_steps.Step3Goal(onNext: _nextStep),
                  final_steps.Step4Ready(onComplete: _completeOnboarding),
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
              // Botón atrás
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed:
                    _currentStep > 0 ? _previousStep : () => context.pop(),
                style: IconButton.styleFrom(
                  backgroundColor:
                      theme.colorScheme.surface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 12),

              // Progress info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Paso ${_currentStep + 1} de $_totalSteps',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Progress bar con animación
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(TerritoryTokens.radiusSmall),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        tween: Tween<double>(begin: 0, end: progress),
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
      ],
    );
  }
}

// ==================== PASO 1: Bienvenida + Datos Básicos ====================

class _Step1WelcomeAndBasics extends ConsumerStatefulWidget {
  final VoidCallback? onNext;

  const _Step1WelcomeAndBasics({this.onNext});

  @override
  ConsumerState<_Step1WelcomeAndBasics> createState() =>
      _Step1WelcomeAndBasicsState();
}

class _Step1WelcomeAndBasicsState extends ConsumerState<_Step1WelcomeAndBasics>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _birthDateController = TextEditingController();
  DateTime? _selectedDate;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _birthDateError;

  @override
  void initState() {
    super.initState();

    // Cargar datos previos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final data = ref.read(onboardingDataProvider);
      _nameController.text = data.displayName;
      setState(() {
        _selectedDate = data.birthDate;
      });
      if (data.birthDate != null) {
        final formatted = _formatDate(data.birthDate!);
        _birthDateController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });

    // Animaciones
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    // Autofocus después de la animación
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _animationController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _selectDate() async {
    HapticFeedback.selectionClick();

    final now = DateTime.now();
    final minDate = DateTime(now.year - 100);
    final maxDate = DateTime(now.year - 13);

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? maxDate,
      firstDate: minDate,
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(TerritoryTokens.radiusMedium),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      HapticFeedback.mediumImpact();
      _applyBirthDate(date);
    }
  }

  void _applyBirthDate(DateTime date) {
    final formatted = _formatDate(date);
    setState(() {
      _selectedDate = date;
      _birthDateError = null;
      _birthDateController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    });
  }

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  DateTime? _tryParseBirthDate(String value) {
    if (value.replaceAll(RegExp(r'[^0-9]'), '').length < 8) {
      return null;
    }
    try {
      final parsed = DateFormat('dd/MM/yyyy').parseStrict(value);
      return parsed;
    } on FormatException {
      return null;
    }
  }

  bool _isWithinAllowedRange(DateTime date) {
    final now = DateTime.now();
    final minDate = DateTime(now.year - 100, now.month, now.day);
    final maxDate = DateTime(now.year - 13, now.month, now.day);
    return !date.isBefore(minDate) && !date.isAfter(maxDate);
  }

  void _onBirthDateChanged(String value) {
    final parsed = _tryParseBirthDate(value);
    if (parsed == null) {
      setState(() {
        if (value.isEmpty) {
          _selectedDate = null;
          _birthDateError = null;
        } else if (value.replaceAll(RegExp(r'[^0-9]'), '').length < 8) {
          _selectedDate = null;
          _birthDateError = null;
        } else {
          _selectedDate = null;
          _birthDateError = 'Fecha inválida';
        }
      });
      return;
    }

    if (!_isWithinAllowedRange(parsed)) {
      setState(() {
        _selectedDate = null;
        _birthDateError = 'Ingresa una fecha entre 13 y 100 años';
      });
      return;
    }

    setState(() {
      _selectedDate = parsed;
      _birthDateError = null;
    });
  }

  void _handleNext() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa tu nombre'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final birthDate =
        _selectedDate ?? _tryParseBirthDate(_birthDateController.text);
    if (birthDate == null || !_isWithinAllowedRange(birthDate)) {
      HapticFeedback.heavyImpact();
      setState(() {
        _birthDateError = 'Por favor ingresa una fecha válida';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona tu fecha de nacimiento'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Guardar datos
    // Diferir la modificación del provider hasta después del frame actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingDataProvider.notifier).updateField((data) {
        data.displayName = name;
        data.birthDate = birthDate;
      });

      // Navegar al siguiente paso
      widget.onNext?.call();
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
    super.build(context);
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Hero illustration
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: SvgPicture.asset(
                    'assets/icons/running.svg',
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                '¡Bienvenido a\nTerritory Run!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Cuéntanos un poco sobre ti',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Nombre
              AeroTextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                label: '¿Cómo te llamas?',
                hint: 'Tu nombre',
                prefixIcon: const Icon(Icons.person_outline),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _selectDate(),
              ),

              const SizedBox(height: 20),

              // Fecha de nacimiento con formateo automático
              AeroTextField(
                controller: _birthDateController,
                label: 'Fecha de nacimiento',
                hint: 'DD/MM/AAAA',
                helperText:
                    _age != null ? 'Edad: $_age años' : 'Formato DD/MM/AAAA',
                errorText: _birthDateError,
                prefixIcon: const Icon(Icons.cake_outlined),
                suffixIcon: IconButton(
                  tooltip: 'Abrir calendario',
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectDate,
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onChanged: _onBirthDateChanged,
                onSubmitted: (_) => _handleNext(),
                inputFormatters: const [_DateTextInputFormatter()],
              ),

              const SizedBox(height: 32),

              AeroButton(
                onPressed: _handleNext,
                child: const Text('Continuar'),
              ),

              const SizedBox(height: 16),

              Text(
                '¡Solo 3 pasos más! 🚀',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== PASO 2: Perfil Físico Consolidado ====================

class _Step2PhysicalProfile extends ConsumerStatefulWidget {
  final VoidCallback? onNext;

  const _Step2PhysicalProfile({this.onNext});

  @override
  ConsumerState<_Step2PhysicalProfile> createState() =>
      _Step2PhysicalProfileState();
}

class _Step2PhysicalProfileState extends ConsumerState<_Step2PhysicalProfile>
    with AutomaticKeepAliveClientMixin {
  String _selectedGender = '';
  double _weight = 70.0;
  int _height = 170;

  @override
  void initState() {
    super.initState();

    // Cargar datos previos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final data = ref.read(onboardingDataProvider);
      setState(() {
        _selectedGender = data.gender;
        _weight = data.weightKg;
        _height = data.heightCm;
      });
    });
  }

  @override
  bool get wantKeepAlive => true;

  void _handleNext() {
    if (_selectedGender.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una opción'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Guardar datos
    // Diferir la modificación del provider hasta después del frame actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingDataProvider.notifier).updateField((data) {
        data.gender = _selectedGender;
        data.weightKg = _weight;
        data.heightCm = _height;
      });

      // Navegar al siguiente paso
      widget.onNext?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          Icon(
            Icons.accessibility_new,
            size: 80,
            color: theme.colorScheme.primary,
          ),

          const SizedBox(height: 24),

          Text(
            'Tu perfil físico',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            'Esto nos ayuda a calcular tus métricas',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Género - versión compacta
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Género',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _GenderChip(
                      icon: Icons.male,
                      label: 'Masculino',
                      value: 'male',
                      isSelected: _selectedGender == 'male',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedGender = 'male');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GenderChip(
                      icon: Icons.female,
                      label: 'Femenino',
                      value: 'female',
                      isSelected: _selectedGender == 'female',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedGender = 'female');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _GenderChip(
                      icon: Icons.more_horiz,
                      label: 'Otro',
                      value: 'other',
                      isSelected: _selectedGender == 'other',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedGender = 'other');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GenderChip(
                      icon: Icons.lock_outline,
                      label: 'Prefiero no decir',
                      value: 'prefer_not_say',
                      isSelected: _selectedGender == 'prefer_not_say',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedGender = 'prefer_not_say');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Peso y Altura en columnas individuales
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PhysicalStatSliderCard(
                title: 'Peso',
                valueLabel: '${_weight.toStringAsFixed(0)} kg',
                icon: Icons.monitor_weight_outlined,
                slider: Slider(
                  value: _weight,
                  min: 30,
                  max: 200,
                  divisions: 170,
                  onChanged: (value) {
                    setState(() => _weight = value);
                  },
                  onChangeEnd: (_) => HapticFeedback.selectionClick(),
                ),
              ),
              const SizedBox(height: 16),
              _PhysicalStatSliderCard(
                title: 'Altura',
                valueLabel: '$_height cm',
                icon: Icons.height,
                slider: Slider(
                  value: _height.toDouble(),
                  min: 100,
                  max: 250,
                  divisions: 150,
                  onChanged: (value) {
                    setState(() => _height = value.round());
                  },
                  onChangeEnd: (_) => HapticFeedback.selectionClick(),
                ),
              ),
            ],
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

class _PhysicalStatSliderCard extends StatelessWidget {
  final String title;
  final String valueLabel;
  final IconData icon;
  final Slider slider;

  const _PhysicalStatSliderCard({
    required this.title,
    required this.valueLabel,
    required this.icon,
    required this.slider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        AeroCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: scheme.primary.withValues(alpha: 0.85),
                ),
                const SizedBox(height: 8),
                Text(
                  valueLabel,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    activeTrackColor: scheme.primary,
                    inactiveTrackColor: scheme.primary.withValues(alpha: 0.2),
                    thumbColor: scheme.primary,
                    overlayColor: scheme.primary.withValues(alpha: 0.12),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 10),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 18),
                  ),
                  child: slider,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DateTextInputFormatter extends TextInputFormatter {
  const _DateTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();

    for (var i = 0; i < digitsOnly.length && i < 8; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
      }
      buffer.write(digitsOnly[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedColor = scheme.primary.withValues(alpha: 0.14);
    final iconColor = isSelected
        ? scheme.primary.withValues(alpha: 0.85)
        : theme.iconTheme.color?.withValues(alpha: 0.6);
    final textColor =
        isSelected ? scheme.primary.withValues(alpha: 0.85) : null;

    return AeroCard(
      onTap: onTap,
      level: AeroLevel.subtle,
      child: AnimatedContainer(
        duration: TerritoryTokens.durationFast,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
          border: Border.all(
            color: isSelected
                ? scheme.primary.withValues(alpha: 0.3)
                : scheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: iconColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Continuará en el siguiente archivo debido al límite de longitud...
