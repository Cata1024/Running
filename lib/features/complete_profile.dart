import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../shared/services.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key, this.existingProfile});

  final UserModel? existingProfile;

  @override
  ConsumerState<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _goalController;
  late final TextEditingController _photoUrlController;

  DateTime? _birthDate;
  String? _selectedGender;
  String _preferredUnits = 'metric';
  bool _isSubmitting = false;
  late final String _email;

  @override
  void initState() {
    super.initState();
    final profile = widget.existingProfile;
    final user = FirebaseAuth.instance.currentUser;

    _nameController = TextEditingController(
      text: profile?.displayName ?? user?.displayName ?? user?.email?.split('@').first ?? '',
    );
    _weightController = TextEditingController(
      text: profile?.weightKg != null ? profile!.weightKg!.toStringAsFixed(1) : '',
    );
    _heightController = TextEditingController(
      text: profile?.heightCm?.toString() ?? '',
    );
    _goalController = TextEditingController(text: profile?.goalDescription ?? '');
    _photoUrlController = TextEditingController(
      text: profile?.photoUrl ?? user?.photoURL ?? '',
    );

    _birthDate = profile?.birthDate;
    _selectedGender = profile?.gender;
    _preferredUnits = profile?.preferredUnits ?? 'metric';
    _email = user?.email ?? profile?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _goalController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    final firstDate = DateTime(now.year - 100);
    final lastDate = DateTime(now.year - 13, now.month, now.day);

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Selecciona tu fecha de nacimiento',
      locale: const Locale('es'),
    );
    if (selected != null) {
      setState(() => _birthDate = selected);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona tu fecha de nacimiento.')),
      );
      return;
    }

    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un peso válido (kg).')),
      );
      return;
    }

    final height = int.tryParse(_heightController.text);
    if (height == null || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una altura válida (cm).')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión expirada. Inicia sesión nuevamente.')),
      );
      return;
    }

    final displayName = _nameController.text.trim();
    final goal = _goalController.text.trim();
    final photoUrl = _photoUrlController.text.trim();
    final base = widget.existingProfile;

    setState(() => _isSubmitting = true);
    try {
      final profile = UserModel(
        id: user.uid,
        email: _email,
        displayName: displayName.isEmpty
            ? (user.displayName ?? user.email?.split('@').first ?? 'Runner')
            : displayName,
        createdAt: base?.createdAt ?? DateTime.now(),
        totalRuns: base?.totalRuns ?? 0,
        totalDistance: base?.totalDistance ?? 0.0,
        totalTime: base?.totalTime ?? 0,
        level: base?.level ?? 1,
        experience: base?.experience ?? 0,
        achievements: base?.achievements ?? const [],
        photoUrl: photoUrl.isNotEmpty ? photoUrl : base?.photoUrl,
        lastActivityAt: base?.lastActivityAt,
        birthDate: _birthDate,
        weightKg: weight,
        heightCm: height,
        gender: _selectedGender,
        preferredUnits: _preferredUnits,
        goalDescription: goal.isNotEmpty ? goal : base?.goalDescription,
      );

      final firestore = ref.read(firestoreServiceProvider);
      await firestore.saveUserProfile(profile);

      if (displayName.isNotEmpty && displayName != user.displayName) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl.isNotEmpty && photoUrl != user.photoURL) {
        await user.updatePhotoURL(photoUrl);
      }

      ref.invalidate(currentUserProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el perfil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _signOut() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = _birthDate != null
        ? DateFormat.yMMMMd('es').format(_birthDate!)
        : 'Selecciona tu fecha de nacimiento';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completa tu perfil'),
        actions: [
          IconButton(
            onPressed: _isSubmitting ? null : _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Bienvenido! Necesitamos algunos datos para personalizar tu experiencia.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _isSubmitting ? null : _pickBirthDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de nacimiento',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateLabel),
                        const Icon(Icons.calendar_today_outlined),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  items: const [
                    DropdownMenuItem(value: 'female', child: Text('Femenino')),
                    DropdownMenuItem(value: 'male', child: Text('Masculino')),
                    DropdownMenuItem(value: 'non_binary', child: Text('No binario')),
                    DropdownMenuItem(value: 'prefer_not', child: Text('Prefiero no decirlo')),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() => _selectedGender = value);
                        },
                  decoration: const InputDecoration(
                    labelText: 'Género (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _preferredUnits,
                  items: const [
                    DropdownMenuItem(value: 'metric', child: Text('Sistema métrico (km, kg)')),
                    DropdownMenuItem(value: 'imperial', child: Text('Sistema imperial (mi, lb)')),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _preferredUnits = value);
                          }
                        },
                  decoration: const InputDecoration(
                    labelText: 'Sistema de medidas',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Altura (cm)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _goalController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Objetivo personal (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _photoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Foto de perfil (URL, opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSubmitting ? 'Guardando…' : 'Guardar y continuar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
