import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_button.dart';
import '../../../core/widgets/aero_surface.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../../data/models/user_profile_dto.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  DateTime? _birthDate;
  String? _selectedGender;
  String? _selectedExperience;
  bool _isLoading = false;
  bool _initializedFromProfile = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentFirebaseUserProvider);
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final name = _nameController.text.trim();
      final weight = double.tryParse(_weightController.text.trim());
      final height = int.tryParse(_heightController.text.trim());

      final experiencePoints = _experienceToPoints(_selectedExperience);

      final payload = <String, dynamic>{
        'displayName': name,
        'gender': _selectedGender,
        'weightKg': weight,
        'heightCm': height,
        'experience': experiencePoints,
        'experienceLevel': _selectedExperience,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (_birthDate != null) {
        payload['birthDate'] = _birthDate!.toIso8601String();
      }
      payload.removeWhere((key, value) => value == null);

      await ref.read(apiServiceProvider).patchUserProfile(user.uid, payload);
      if (name.isNotEmpty) {
        await ref.read(authServiceProvider).updateProfile(displayName: name);
      }

      ref.invalidate(userProfileDtoProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
        context.go('/map');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el perfil: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _loadProfile(UserProfileDto dto) {
    final displayName = dto.displayName;
    final gender = dto.gender;
    final weight = dto.weightKg;
    final height = dto.heightCm;
    final birthDate = dto.birthDate;
    final experience = dto.experience;
    final experienceLevel = _experienceFromPoints(experience);

    if (displayName != null && displayName.isNotEmpty) {
      _nameController.text = displayName;
    }
    if (birthDate != null) {
      _birthDate = birthDate;
    }
    if (weight != null) {
      _weightController.text = _formatNumber(weight);
    }
    if (height != null) {
      _heightController.text = height.toString();
    }
    _selectedGender = gender;
    _selectedExperience = experienceLevel;
  }

  

  static String _formatNumber(double value) {
    final isInteger = value % 1 == 0;
    return isInteger ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  static String? _experienceFromPoints(dynamic value) {
    if (value is int) {
      if (value >= 1000) return 'advanced';
      if (value >= 400) return 'intermediate';
      if (value >= 0) return 'beginner';
    }
    return null;
  }

  static int? _experienceToPoints(String? value) {
    switch (value) {
      case 'beginner':
        return 0;
      case 'intermediate':
        return 400;
      case 'advanced':
        return 1000;
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 13), // Mínimo 13 años
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navBarHeight = ref.watch(navBarHeightProvider);
    final profileAsync = ref.watch(userProfileDtoProvider);

    profileAsync.when(
      data: (dto) {
        if (!_initializedFromProfile && dto != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _loadProfile(dto);
              _initializedFromProfile = true;
            });
          });
        } else if (!_initializedFromProfile) {
          _initializedFromProfile = true;
        }
      },
      error: (_, __) {
        if (!_initializedFromProfile) {
          _initializedFromProfile = true;
        }
      },
      loading: () {},
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Perfil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: AppTheme.paddingLarge.copyWith(
          bottom: AppTheme.paddingLarge.bottom + (navBarHeight - TerritoryTokens.space16).clamp(0, double.infinity),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              AeroSurface(
                level: AeroLevel.medium,
                borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
                padding: const EdgeInsets.all(TerritoryTokens.space24),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_add_alt_1,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: TerritoryTokens.space16),
                    Text(
                      '¡Bienvenido a Territory Run!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: TerritoryTokens.space8),
                    Text(
                      'Completa tu perfil para personalizar tu experiencia',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TerritoryTokens.space24),
              
              // Form Fields
              AeroSurface(
                level: AeroLevel.medium,
                borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
                padding: const EdgeInsets.all(TerritoryTokens.space24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información Personal',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: TerritoryTokens.space24),
                    
                    // Name
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        hintText: 'Tu nombre',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: TerritoryTokens.space16),
                    
                    // Birthdate and Gender Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectBirthDate(context),
                            borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Fecha de Nacimiento',
                                hintText: 'Selecciona tu fecha',
                                prefixIcon: const Icon(Icons.cake),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                                ),
                              ),
                              child: Text(
                                _birthDate != null
                                    ? _formatDate(_birthDate!)
                                    : 'Selecciona tu fecha',
                                style: TextStyle(
                                  color: _birthDate != null
                                      ? Theme.of(context).textTheme.bodyLarge?.color
                                      : Theme.of(context).hintColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: TerritoryTokens.space16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Género',
                              prefixIcon: Icon(Icons.wc),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'male', child: Text('Masculino')),
                              DropdownMenuItem(value: 'female', child: Text('Femenino')),
                              DropdownMenuItem(value: 'other', child: Text('Otro')),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedGender = value);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Selecciona género';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TerritoryTokens.space16),
                    
                    // Weight and Height Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Peso (kg)',
                              hintText: '70',
                              prefixIcon: Icon(Icons.monitor_weight),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requerido';
                              }
                              final weight = double.tryParse(value);
                              if (weight == null || weight < 30 || weight > 300) {
                                return 'Peso inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: TerritoryTokens.space16),
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Altura (cm)',
                              hintText: '175',
                              prefixIcon: Icon(Icons.height),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requerido';
                              }
                              final height = int.tryParse(value);
                              if (height == null || height < 100 || height > 250) {
                                return 'Altura inválida';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TerritoryTokens.space16),
                    
                    // Experience Level
                    DropdownButtonFormField<String>(
                      initialValue: _selectedExperience,
                      decoration: const InputDecoration(
                        labelText: 'Nivel de Experiencia',
                        prefixIcon: Icon(Icons.fitness_center),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'beginner',
                          child: Text('Principiante - Recién empiezo'),
                        ),
                        DropdownMenuItem(
                          value: 'intermediate',
                          child: Text('Intermedio - Corro regularmente'),
                        ),
                        DropdownMenuItem(
                          value: 'advanced',
                          child: Text('Avanzado - Muy experimentado'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedExperience = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona tu nivel de experiencia';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Save Button
              AeroButton(
                onPressed: _isLoading ? null : _handleSave,
                isLoading: _isLoading,
                height: 56,
                child: const Text('Guardar y Continuar'),
              ),
              const SizedBox(height: 16),
              
              // Skip Button
              TextButton(
                onPressed: () => context.go('/map'),
                child: const Text('Saltar por ahora'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
