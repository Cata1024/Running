import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_widgets.dart';
import '../../../core/widgets/avatar_picker.dart';
import '../../../l10n/app_localizations.dart';
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
    final dto = ref.read(userProfileDtoProvider).value;
    if (dto != null && mounted) {
      setState(() {
        _nameController.text = dto.displayName ?? '';
        _birthDate = dto.birthDate;
        _selectedGender = dto.gender ?? '';
        _weight = dto.weightKg ?? 70.0;
        _height = dto.heightCm ?? 170;
        _selectedGoal = dto.goalType ?? '';
        _weeklyGoal = dto.weeklyDistanceGoal ?? 20.0;
        _goalDescription = dto.goalDescription;
      });
    }
    
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
        if (_birthDate != null) 'birthDate': _birthDate!.toIso8601String(),
        'gender': _selectedGender,
        'weightKg': _weight,
        'heightCm': _height,
        'goalType': _selectedGoal,
        'weeklyDistanceGoal': _weeklyGoal,
        if (_goalDescription != null && _goalDescription!.isNotEmpty)
          'goalDescription': _goalDescription,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      // Actualizar en Firestore
      await api.updateUserProfile(user.uid, updates);
      
      // Invalidar provider para recargar
      ref.invalidate(userProfileDtoProvider);
      
      if (!mounted) return;
      
      // Mostrar éxito y volver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${AppLocalizations.of(context).profileUpdated}'),
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
          content: Text('❌ ${AppLocalizations.of(context).profileUpdateFailed}'),
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
              title: Text(AppLocalizations.of(context).editProfile),
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
                        : Text(AppLocalizations.of(context).save),
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
                        imageUrl: ref.read(userProfileDtoProvider).value?.photoUrl,
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
                        title: AppLocalizations.of(context).basicInformation,
                        children: [
                AeroTextField(
                  controller: _nameController,
                  label: AppLocalizations.of(context).fullName,
                  hint: AppLocalizations.of(context).yourName,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context).nameIsRequired;
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
                                AppLocalizations.of(context).birthDate,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _birthDate == null
                                    ? AppLocalizations.of(context).selectDate
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
              title: AppLocalizations.of(context).gender,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _GenderChip(
                        icon: Icons.male,
                        label: AppLocalizations.of(context).male,
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
                        label: AppLocalizations.of(context).female,
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
                        label: AppLocalizations.of(context).other,
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
                        label: AppLocalizations.of(context).preferNotSay,
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
              title: AppLocalizations.of(context).physicalProfile,
              children: [
                _PhysicalStatCard(
                  label: AppLocalizations.of(context).weight,
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
                  label: AppLocalizations.of(context).height,
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
              title: AppLocalizations.of(context).runningGoal,
              children: [
                _GoalOption(
                  icon: Icons.fitness_center,
                  label: AppLocalizations.of(context).fitnessGeneral,
                  description: AppLocalizations.of(context).stayActive,
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
                  label: AppLocalizations.of(context).weightLoss,
                  description: AppLocalizations.of(context).loseWeight,
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
                  label: AppLocalizations.of(context).competition,
                  description: AppLocalizations.of(context).prepareForRaces,
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
                  label: AppLocalizations.of(context).fun,
                  description: AppLocalizations.of(context).enjoyRunning,
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
              title: AppLocalizations.of(context).weeklyGoal,
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
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context).unsavedChanges),
        content: Text(AppLocalizations.of(context).unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context).discard),
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
