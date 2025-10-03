import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../shared/services.dart';
import 'navigation.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final authService = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return _emptyState(context);
          return _buildProfileContent(context, ref, profile, authService);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('Error al cargar perfil: $e'),
        ),
      ),
    );
  }

  Widget _personalInfoCard(BuildContext context, UserModel profile) {
    final cs = Theme.of(context).colorScheme;
    final birthDateLabel = profile.birthDate != null
        ? DateFormat.yMMMd('es').format(profile.birthDate!)
        : '--';
    final ageLabel = profile.age?.toString() ?? '--';
    final bmiLabel = profile.bmi != null ? profile.bmi!.toStringAsFixed(1) : '--';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.badge, color: cs.primary),
                const SizedBox(width: 8),
                Text('Datos personales',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow('Nombre', profile.displayName),
            _infoRow('Edad', ageLabel),
            _infoRow('Fecha de nacimiento', birthDateLabel),
            _infoRow('Peso', _formatWeight(profile)),
            _infoRow('Altura', _formatHeight(profile)),
            _infoRow('IMC', bmiLabel),
            if (profile.gender != null && profile.gender!.isNotEmpty)
              _infoRow('Género', _genderLabel(profile.gender!)),
            _infoRow('Sistema de medidas',
                profile.preferredUnits == 'imperial' ? 'Imperial (mi, lb)' : 'Métrico (km, kg)'),
            if (profile.goalDescription != null &&
                profile.goalDescription!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Objetivo personal',
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(profile.goalDescription!),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatWeight(UserModel profile) {
    if (profile.weightKg == null) return '--';
    if (profile.preferredUnits == 'imperial') {
      final pounds = profile.weightKg! * 2.2046226218;
      return '${pounds.toStringAsFixed(1)} lb';
    }
    return '${profile.weightKg!.toStringAsFixed(1)} kg';
  }

  String _formatHeight(UserModel profile) {
    if (profile.heightCm == null) return '--';
    if (profile.preferredUnits == 'imperial') {
      final totalInches = profile.heightCm! / 2.54;
      final feet = totalInches ~/ 12;
      final inches = totalInches - (feet * 12);
      if (feet > 0) {
        return "${feet.toString()} ft ${inches.toStringAsFixed(1)} in";
      }
      return '${inches.toStringAsFixed(1)} in';
    }
    return '${profile.heightCm} cm';
  }

  String _genderLabel(String code) {
    switch (code) {
      case 'female':
        return 'Femenino';
      case 'male':
        return 'Masculino';
      case 'non_binary':
        return 'No binario';
      case 'prefer_not':
        return 'Prefiero no decirlo';
    }
    return code;
  }

  Widget _accountInfoSection(
    BuildContext context,
    AuthService authService,
    String email,
  ) {
    final cs = Theme.of(context).colorScheme;
    final providers = authService.currentUser?.providerData ?? const [];
    final providerLabels = providers.isEmpty
        ? ['Sin proveedores vinculados']
        : providers.map((info) {
            final providerId = info.providerId;
            if (providerId == EmailAuthProvider.PROVIDER_ID) {
              return 'Email y contraseña';
            }
            if (providerId == GoogleAuthProvider.PROVIDER_ID) {
              return 'Google';
            }
            return providerId;
          }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: cs.primary),
                const SizedBox(width: 8),
                Text('Información de cuenta',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text('Correo', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            SelectableText(email, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text('Proveedores vinculados',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  providerLabels.map((label) => Chip(label: Text(label))).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Construcción principal del perfil
  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    UserModel profile,
    AuthService authService,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con avatar y datos básicos
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: cs.primaryContainer,
                      backgroundImage:
                          profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
                      child: profile.photoUrl == null
                          ? Icon(Icons.person, color: cs.onPrimaryContainer, size: 32)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.displayName, style: Theme.of(context).textTheme.titleLarge),
                          Text(
                            profile.email,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tarjeta de nivel
                _levelCard(
                  context,
                  profile.level,
                  profile.levelProgress,
                  profile.experience,
                  profile.nextLevelExperience,
                ),
                const SizedBox(height: 16),

                // Stats
                _statsGrid(
                  context,
                  profile.totalRuns,
                  profile.totalDistance,
                  profile.totalTime,
                  profile.averagePace,
                  profile.averageSpeed,
                ),
                const SizedBox(height: 16),

                _personalInfoCard(context, profile),
                const SizedBox(height: 16),

                // Logros
                Text('Logros', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.achievements.isNotEmpty
                      ? profile.achievements.map((a) => Chip(label: Text(a))).toList()
                      : [
                          Text(
                            'Aún no hay logros',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ],
                ),
                const SizedBox(height: 16),

                // Información de cuenta
                _accountInfoSection(context, authService, profile.email),
                const SizedBox(height: 16),

                // Sección de credenciales
                _credentialsSection(context, ref, authService, profile.email),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref.read(navIndexProvider.notifier).state = 0,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Ver territorios'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Estado vacío
  Widget _emptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('No hay información de perfil'),
          ],
        ),
      ),
    );
  }

  /// Tarjeta de nivel
  Widget _levelCard(BuildContext context, int level, double progress, int xp,
      int nextLevelXp) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: cs.primary),
                const SizedBox(width: 8),
                Text('Nivel $level',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, minHeight: 8),
            const SizedBox(height: 8),
            Text('$xp / $nextLevelXp XP',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  /// Grid de estadísticas
  Widget _statsGrid(BuildContext context, int totalRuns, double totalDistance,
      int totalTime, double avgPace, double avgSpeed) {
    final items = [
      _StatItem(
          icon: Icons.directions_run, label: 'Carreras', value: '$totalRuns'),
      _StatItem(
          icon: Icons.route,
          label: 'Distancia',
          value: '${totalDistance.toStringAsFixed(1)} km'),
      _StatItem(
          icon: Icons.timelapse,
          label: 'Tiempo',
          value: _formatDuration(Duration(seconds: totalTime))),
      _StatItem(
          icon: Icons.speed,
          label: 'Ritmo prom',
          value: avgPace > 0 ? '${avgPace.toStringAsFixed(1)} min/km' : '--'),
      _StatItem(
          icon: Icons.flash_on,
          label: 'Velocidad',
          value: '${avgSpeed.toStringAsFixed(1)} km/h'),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: items
          .map((item) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(item.icon),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(item.value,
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(item.label,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  /// Formato de duración
  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Sección credenciales
  Widget _credentialsSection(BuildContext context, WidgetRef ref,
      AuthService authService, String email) {
    final hasEmailProvider = authService.hasEmailPasswordProvider;
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.login, color: cs.primary),
                const SizedBox(width: 8),
                Text('Acceso con email/contraseña',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hasEmailProvider
                  ? 'Ya puedes iniciar sesión con tu correo y contraseña.'
                  : 'Actualmente tu cuenta usa inicio con Google. Crea una contraseña para usar el acceso tradicional.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!hasEmailProvider) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _promptSetPassword(context, ref, email),
                icon: const Icon(Icons.lock_reset),
                label: const Text('Crear contraseña'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Diálogo para setear contraseña
  Future<void> _promptSetPassword(
      BuildContext context, WidgetRef ref, String email) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var isSubmitting = false;

    Future<void> linkCredentials() async {
      final authService = ref.read(authServiceProvider);
      await authService.linkEmailPassword(
        email,
        passwordController.text.trim(),
      );
      await authService.reloadUser();
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentUserProfileProvider);
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Crear contraseña'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Usaremos tu correo $email'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nueva contraseña',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa una contraseña';
                        }
                        if (value.length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirma la contraseña';
                        }
                        if (value != passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => isSubmitting = true);
                          try {
                            await linkCredentials();
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Contraseña creada correctamente.'),
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            String message = 'No se pudo crear la contraseña.';
                            switch (e.code) {
                              case 'provider-already-linked':
                              case 'credential-already-in-use':
                                message =
                                    'Esta cuenta ya tiene proveedor de email/contraseña configurado.';
                                break;
                              case 'email-already-in-use':
                                message =
                                    'El correo ya está en uso en otra cuenta.';
                                break;
                              case 'requires-recent-login':
                                message =
                                    'Vuelve a iniciar sesión y reintenta.';
                                break;
                            }
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Error inesperado creando la contraseña.')),
                              );
                            }
                          } finally {
                            setState(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    confirmController.dispose();
  }
}

/// Modelo para los ítems de estadísticas
class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  _StatItem({required this.icon, required this.label, required this.value});
}
