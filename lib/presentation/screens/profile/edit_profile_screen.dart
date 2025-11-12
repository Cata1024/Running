import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_widgets.dart';
import '../../../core/widgets/avatar_picker.dart';
import '../../../core/services/avatar_uploader.dart';
import '../../../data/models/user_profile_dto.dart';
import 'package:running/l10n/app_localizations.dart';
import '../../providers/app_providers.dart';

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
  bool _hasInitializedFromDto = false;
  bool _isProgrammaticUpdate = false;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_markAsChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _markAsChanged() {
    if (_isProgrammaticUpdate) {
      return;
    }
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  void _initializeFromDto(UserProfileDto? dto) {
    if (_hasInitializedFromDto || dto == null) {
      return;
    }

    _isProgrammaticUpdate = true;
    _nameController.text = dto.displayName ?? '';
    _birthDate = dto.birthDate;
    _selectedGender = dto.gender ?? '';
    _weight = dto.weightKg ?? _weight;
    _height = dto.heightCm ?? _height;
    _selectedGoal = dto.goalType ?? _selectedGoal;
    _weeklyGoal = dto.weeklyDistanceGoal ?? _weeklyGoal;
    _goalDescription = dto.goalDescription;
    _isProgrammaticUpdate = false;

    _hasInitializedFromDto = true;
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
        newAvatarUrl = await AvatarUploader.uploadAvatar(
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

      // Sincronizar avatar con Firebase Auth para reflejar el cambio inmediatamente
      if (newAvatarUrl != null) {
        try {
          await user.updatePhotoURL(newAvatarUrl);
          await user.reload();
        } on FirebaseAuthException {
          // Ignorar; el backend ya guarda la URL y la próxima sesión obtendrá el valor correcto.
        }
      }

      // Invalidar provider para recargar
      _hasInitializedFromDto = false;
      ref.invalidate(userProfileDtoProvider);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _newAvatarFile = null;
        _hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${_l10n.profileUpdated}'),
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
          content: Text('❌ ${_l10n.profileUpdateFailed}'),
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
    final profileAsync = ref.watch(userProfileDtoProvider);
    return profileAsync.when(
      data: (dto) {
        _initializeFromDto(dto);
        return _buildScaffold(context, dto);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(TerritoryTokens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: TerritoryTokens.space12),
                Text(
                  'No se pudo cargar el perfil',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: TerritoryTokens.space16),
                TextButton.icon(
                  onPressed: () => ref.invalidate(userProfileDtoProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, UserProfileDto? dto) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final l10n = _l10n;
    final bottomContentPadding = mediaQuery.padding.bottom + TerritoryTokens.space32;

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: true,
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(l10n.editProfile),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _confirmExit(),
                ),
                actions: [
                  if (_hasChanges)
                    FilledButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      child: Text(
                        l10n.save,
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                ],
                pinned: true,
                floating: true,
              ),
              SliverPadding(
                padding: EdgeInsets.only(bottom: bottomContentPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.all(TerritoryTokens.space16),
                      child: Column(
                        children: [
                          AvatarPicker(
                            imageUrl: dto?.photoUrl,
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

                          // Información básica
                          _buildSection(
                            title: l10n.basicInformation,
                            children: [
                              AeroTextField(
                                controller: _nameController,
                                label: l10n.fullName,
                                hint: l10n.yourName,
                                prefixIcon: const Icon(Icons.person_outline),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n.nameIsRequired;
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
                                              l10n.birthDate,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _birthDate == null
                                                  ? l10n.selectDate
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
                          const SizedBox(height: TerritoryTokens.space32),

                          // Género
                          _buildSection(
                            title: l10n.gender,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _GenderChip(
                                      icon: Icons.male,
                                      label: l10n.male,
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
                                      label: l10n.female,
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
                              const SizedBox(height: TerritoryTokens.space12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _GenderChip(
                                      icon: Icons.more_horiz,
                                      label: l10n.other,
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
                                      label: l10n.preferNotSay,
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

                          // Perfil físico
                          _buildSection(
                            title: l10n.physicalProfile,
                            children: [
                              _PhysicalStatCard(
                                label: l10n.weight,
                                icon: Icons.monitor_weight_outlined,
                                value: _weight,
                                unit: 'kg',
                                min: 30,
                                max: 200,
                                step: 0.5,
                                onChanged: (value) {
                                  setState(() {
                                    _weight = value;
                                    _hasChanges = true;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              _PhysicalStatCard(
                                label: l10n.height,
                                icon: Icons.height,
                                value: _height.toDouble(),
                                unit: 'cm',
                                min: 100,
                                max: 250,
                                step: 1,
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
                            title: l10n.runningGoal,
                            children: [
                              _GoalOption(
                                icon: Icons.fitness_center,
                                label: l10n.fitnessGeneral,
                                description: l10n.stayActive,
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
                                label: l10n.weightLoss,
                                description: l10n.loseWeight,
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
                                icon: Icons.emoji_events_outlined,
                                label: l10n.competition,
                                description: l10n.prepareForRaces,
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
                                icon: Icons.sentiment_satisfied_outlined,
                                label: l10n.fun,
                                description: l10n.enjoyRunning,
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
                            title: l10n.weeklyGoal,
                            children: [
                              AeroCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Icon(Icons.track_changes, size: 40, color: theme.colorScheme.primary),
                                      const SizedBox(height: 16),
                                      Text(
                                        '${_weeklyGoal.toStringAsFixed(0)} km',
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Slider(
                                        value: _weeklyGoal,
                                        min: 5,
                                        max: 100,
                                        divisions: 95,
                                        label: '${_weeklyGoal.round()} km',
                                        onChanged: (value) {
                                          setState(() {
                                            _weeklyGoal = value;
                                            _hasChanges = true;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        l10n.goal,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l10n.goalWeekly,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        initialValue: _goalDescription ?? '',
                                        minLines: 3,
                                        maxLines: 5,
                                        onChanged: (value) {
                                          setState(() {
                                            _goalDescription = value;
                                            _hasChanges = true;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: l10n.goalDescription,
                                          border: const OutlineInputBorder(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: TerritoryTokens.space32),

                          // Botón Guardar
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
                                : Text(l10n.save),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
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

    final l10n = _l10n;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.unsavedChanges),
        content: Text(l10n.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.discard),
          ),
        ],
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
    final scheme = theme.colorScheme;

    return AeroCard(
      level: isSelected ? AeroLevel.medium : AeroLevel.ghost,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: isSelected
            ? BoxDecoration(
                border: Border.all(
                  color: scheme.primary,
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
                    ? scheme.primary.withValues(alpha: 0.2)
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
              ),
              child: Icon(
                icon,
                color: isSelected ? scheme.primary : theme.iconTheme.color,
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
                      color: isSelected ? scheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                color: scheme.primary,
              ),
          ],
        ),
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
            Icon(icon, size: 28, color: isSelected ? scheme.primary : scheme.onSurfaceVariant),
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
  final double step;
  final ValueChanged<double> onChanged;

  const _PhysicalStatCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
  });

  int get _divisions => ((max - min) / step).round();

  int get _fractionDigits {
    final stepString = step.toString();
    if (!stepString.contains('.')) return 0;
    final trimmed = stepString.split('.').last.replaceAll(RegExp(r'0+'), '');
    return trimmed.isEmpty ? 0 : trimmed.length;
  }

  double _snapToStep(double raw) {
    final steps = ((raw - min) / step).round();
    final snapped = min + steps * step;
    if (_fractionDigits == 0) {
      return double.parse(snapped.toStringAsFixed(0));
    }
    return double.parse(snapped.toStringAsFixed(_fractionDigits));
  }

  String get _stepLabel => step % 1 == 0
      ? '${step.toStringAsFixed(0)} $unit'
      : '${step.toStringAsFixed(_fractionDigits)} $unit';

  String get _valueLabel => step % 1 == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(_fractionDigits);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sliderValue = _snapToStep(value.clamp(min, max));
    final canDecrease = sliderValue > min;
    final canIncrease = sliderValue < max;

    void handleDelta(double delta) {
      final next = _snapToStep((sliderValue + delta).clamp(min, max));
      onChanged(next);
    }

    Widget buildAdjustButton(IconData icon, VoidCallback? onPressed) {
      return SizedBox(
        width: 48,
        height: 48,
        child: FilledButton.tonal(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
          ),
          child: Icon(icon),
        ),
      );
    }

    return AeroCard(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                    ),
                    child: Icon(icon, color: scheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_valueLabel $unit',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TerritoryTokens.space16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  activeTrackColor: scheme.primary,
                  inactiveTrackColor: scheme.primary.withValues(alpha: 0.2),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                ),
                child: Slider(
                  value: sliderValue,
                  min: min,
                  max: max,
                  divisions: _divisions > 0 ? _divisions : null,
                  label: '$_valueLabel $unit',
                  onChanged: (raw) => onChanged(_snapToStep(raw)),
                ),
              ),
              const SizedBox(height: TerritoryTokens.space12),
              Row(
                children: [
                  buildAdjustButton(Icons.remove, canDecrease ? () => handleDelta(-step) : null),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          l10n.adjustmentStep,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _stepLabel,
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  buildAdjustButton(Icons.add, canIncrease ? () => handleDelta(step) : null),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
