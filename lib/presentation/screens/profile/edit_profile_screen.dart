import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_widgets.dart';
import '../../../core/widgets/avatar_picker.dart';
import '../../providers/app_providers.dart';
import 'dart:io';

/// Pantalla completa para editar el perfil del usuario
/// Incluye: nombre, foto, datos físicos (peso, altura), objetivo, meta semanal
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  DateTime? _birthDate;
  String _selectedGender = '';
  double _weight = 70.0;
  int _height = 170;
  String _selectedGoal = '';
  double _weeklyGoal = 20.0;
  String? _goalDescription;
  File? _newAvatarFile;
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    final profileAsync = ref.read(userProfileDocProvider);
    profileAsync.whenData((data) {
      if (data != null && mounted) {
        // Manejar birthDate que puede venir como Timestamp (Firestore) o DateTime
        DateTime? birthDate;
        final birthDateValue = data['birthDate'];
        if (birthDateValue != null) {
          if (birthDateValue is Timestamp) {
            birthDate = birthDateValue.toDate();
          } else if (birthDateValue is DateTime) {
            birthDate = birthDateValue;
          }
        }
        
        setState(() {
          _nameController.text = data['displayName'] as String? ?? '';
          _birthDate = birthDate;
          _selectedGender = data['gender'] as String? ?? '';
          _weight = (data['weightKg'] as num?)?.toDouble() ?? 70.0;
          _height = (data['heightCm'] as num?)?.toInt() ?? 170;
          _selectedGoal = data['goalType'] as String? ?? '';
          _weeklyGoal = (data['weeklyDistanceGoal'] as num?)?.toDouble() ?? 20.0;
          _goalDescription = data['goalDescription'] as String?;
        });
      }
    });
    
    // Escuchar cambios
    _nameController.addListener(() => _markAsChanged());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _selectDate() async {
    HapticFeedback.selectionClick();
    
    final now = DateTime.now();
    final minDate = DateTime(now.year - 100);
    final maxDate = DateTime(now.year - 13);
    
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? maxDate,
      firstDate: minDate,
      lastDate: maxDate,
    );
    
    if (date != null && date != _birthDate) {
      setState(() {
        _birthDate = date;
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    
    try {
      final api = ref.read(apiServiceProvider);
      final user = ref.read(currentFirebaseUserProvider);
      
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Subir nuevo avatar si existe
      String? newAvatarUrl;
      if (_newAvatarFile != null) {
        newAvatarUrl = await AvatarUploader.uploadToFirebase(
          file: _newAvatarFile!,
          userId: user.uid,
        );
      }

      // Preparar datos a actualizar
      final updates = <String, dynamic>{
        if (newAvatarUrl != null) 'photoUrl': newAvatarUrl,
        'displayName': _nameController.text.trim(),
        if (_birthDate != null) 'birthDate': _birthDate,
        'gender': _selectedGender,
        'weightKg': _weight,
        'heightCm': _height,
        'goalType': _selectedGoal,
        'weeklyDistanceGoal': _weeklyGoal,
        if (_goalDescription != null && _goalDescription!.isNotEmpty)
          'goalDescription': _goalDescription,
        'updatedAt': DateTime.now(),
      };
      
      // Actualizar en Firestore
      await api.updateUserProfile(user.uid, updates);
      
      // Invalidar provider para recargar
      ref.invalidate(userProfileDocProvider);
      
      if (!mounted) return;
      
      // Mostrar éxito y volver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Perfil actualizado correctamente'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
          ),
        ),
      );
      
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Editar Perfil'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _confirmExit(),
              ),
              actions: [
                if (_hasChanges)
                  TextButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar'),
                  ),
              ],
              pinned: true,
              floating: true,
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.all(TerritoryTokens.space16), 
                  child: Column(
                    children: [
                      AvatarPicker(
                        imageUrl: ref.read(userProfileDocProvider).value?['photoUrl'] as String?,
                        onImageSelected: (file) {
                          setState(() {
                            _newAvatarFile = file;
                            _hasChanges = true;
                          });
                          return Future.value();
                        },
                        size: 120,
                      ),
                      const SizedBox(height: TerritoryTokens.space24),
                      // Nombre
                      _buildSection(
                        title: 'Información Básica',
                        children: [
                AeroTextField(
                  controller: _nameController,
                  label: 'Nombre completo',
                  hint: 'Tu nombre',
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: TerritoryTokens.space16),
                
                // Fecha de nacimiento
                AeroCard(
                  onTap: _selectDate,
                  child: Padding(
                    padding: const EdgeInsets.all(TerritoryTokens.space16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _birthDate != null
                                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
                          ),
                          child: Icon(
                            Icons.cake_outlined,
                            color: _birthDate != null
                                ? theme.colorScheme.primary
                                : theme.iconTheme.color,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fecha de nacimiento',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _birthDate == null
                                    ? 'Selecciona tu fecha'
                                    : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _birthDate != null
                                      ? theme.colorScheme.primary
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                ],
              ),
              
              const SizedBox(height: TerritoryTokens.space24),
              
              // Género
              _buildSection(
              title: 'Género',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _GenderChip(
                        icon: Icons.male,
                        label: 'Masculino',
                        value: 'male',
                        isSelected: _selectedGender == 'male',
                        onTap: () {
                          setState(() {
                            _selectedGender = 'male';
                            _hasChanges = true;
                          });
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
                          setState(() {
                            _selectedGender = 'female';
                            _hasChanges = true;
                          });
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
                          setState(() {
                            _selectedGender = 'other';
                            _hasChanges = true;
                          });
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
                          setState(() {
                            _selectedGender = 'prefer_not_say';
                            _hasChanges = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                ],
              ),
              
              const SizedBox(height: TerritoryTokens.space24),
              
              // Perfil Físico
              _buildSection(
              title: 'Perfil Físico',
              children: [
                _PhysicalStatCard(
                  label: 'Peso',
                  icon: Icons.monitor_weight_outlined,
                  value: _weight,
                  unit: 'kg',
                  min: 30,
                  max: 200,
                  divisions: 170,
                  onChanged: (value) {
                    setState(() {
                      _weight = value;
                      _hasChanges = true;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _PhysicalStatCard(
                  label: 'Altura',
                  icon: Icons.height,
                  value: _height.toDouble(),
                  unit: 'cm',
                  min: 100,
                  max: 250,
                  divisions: 150,
                  onChanged: (value) {
                    setState(() {
                      _height = value.round();
                      _hasChanges = true;
                    });
                  },
                ),
                ],
              ),
              
              const SizedBox(height: TerritoryTokens.space24),
              
              // Objetivo
              _buildSection(
              title: 'Objetivo de Carrera',
              children: [
                _GoalOption(
                  icon: Icons.fitness_center,
                  label: 'Fitness General',
                  description: 'Mantenerme activo y saludable',
                  value: 'fitness',
                  isSelected: _selectedGoal == 'fitness',
                  onTap: () {
                    setState(() {
                      _selectedGoal = 'fitness';
                      _weeklyGoal = 15.0;
                      _hasChanges = true;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _GoalOption(
                  icon: Icons.trending_down,
                  label: 'Perder Peso',
                  description: 'Quemar calorías y adelgazar',
                  value: 'weight_loss',
                  isSelected: _selectedGoal == 'weight_loss',
                  onTap: () {
                    setState(() {
                      _selectedGoal = 'weight_loss';
                      _weeklyGoal = 25.0;
                      _hasChanges = true;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _GoalOption(
                  icon: Icons.emoji_events,
                  label: 'Competir',
                  description: 'Prepararme para carreras',
                  value: 'competition',
                  isSelected: _selectedGoal == 'competition',
                  onTap: () {
                    setState(() {
                      _selectedGoal = 'competition';
                      _weeklyGoal = 35.0;
                      _hasChanges = true;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _GoalOption(
                  icon: Icons.sentiment_satisfied_alt,
                  label: 'Diversión',
                  description: 'Disfrutar corriendo sin presión',
                  value: 'fun',
                  isSelected: _selectedGoal == 'fun',
                  onTap: () {
                    setState(() {
                      _selectedGoal = 'fun';
                      _weeklyGoal = 10.0;
                      _hasChanges = true;
                    });
                  },
                ),
                ],
              ),
              
              const SizedBox(height: TerritoryTokens.space24),
              
              // Meta semanal
              _buildSection(
              title: 'Meta Semanal',
              children: [
                AeroCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.track_changes,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${_weeklyGoal.toStringAsFixed(0)} km',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'por semana',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Slider(
                          value: _weeklyGoal,
                          min: 5,
                          max: 100,
                          divisions: 19,
                          label: '${_weeklyGoal.toStringAsFixed(0)} km',
                          onChanged: (value) {
                            setState(() {
                              _weeklyGoal = value;
                              _hasChanges = true;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('5 km', style: theme.textTheme.bodySmall),
                            Text('100 km', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                ],
              ),
              
              const SizedBox(height: TerritoryTokens.space32),
              
              // Botón guardar (también está en el AppBar)
              AeroButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Guardando...'),
                      ],
                    )
                  : const Text('Guardar Cambios'),
              ), 
              
              const SizedBox(height: TerritoryTokens.space16),
            ],
          ),
        ),
      ]),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
  
  void _confirmExit() {
    if (!_hasChanges) {
      context.pop();
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text('Tienes cambios sin guardar. ¿Estás seguro de que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Descartar'),
          ),
        ],
      ),
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

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primaryContainer : scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
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

class _PhysicalStatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final String unit;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _PhysicalStatCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AeroCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: scheme.primary),
                const SizedBox(width: 8),
                Text(label, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${value.toStringAsFixed(0)} $unit',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalOption({
    required this.icon,
    required this.label,
    required this.description,
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
        padding: const EdgeInsets.all(16),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.2)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.iconTheme.color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
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
