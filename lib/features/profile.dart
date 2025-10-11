import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../shared/services.dart';
import 'navigation.dart';
import 'profile/widgets/level_card.dart';
import 'profile/widgets/personal_info_card.dart';
import 'profile/widgets/profile_header.dart';
import 'profile/widgets/profile_stats_grid.dart';

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
                ProfileHeader(profile: profile),
                const SizedBox(height: 16),

                // Tarjeta de nivel
                LevelCard(
                  level: profile.level,
                  progress: profile.levelProgress,
                  experience: profile.experience,
                  nextLevelExperience: profile.nextLevelExperience,
                ),
                const SizedBox(height: 16),

                // Stats
                ProfileStatsGrid(
                  totalRuns: profile.totalRuns,
                  totalDistance: profile.totalDistance,
                  totalTime: profile.totalTime,
                  averagePace: profile.averagePace,
                  averageSpeed: profile.averageSpeed,
                ),
                const SizedBox(height: 16),

                PersonalInfoCard(profile: profile),
                const SizedBox(height: 16),

                // Logros
                Text('Logros', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.achievements.isNotEmpty
                      ? profile.achievements
                          .map((a) => Chip(label: Text(a)))
                          .toList()
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
                    onPressed: () =>
                        ref.read(navIndexProvider.notifier).state = 0,
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
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/auth', (route) => false);
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

  Widget _accountInfoSection(
    BuildContext context,
    AuthService authService,
    String email,
  ) {
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
                Icon(Icons.account_circle, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Información de cuenta',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text('Correo', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            SelectableText(email,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text('Proveedores vinculados',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: providerLabels
                  .map((label) => Chip(label: Text(label)))
                  .toList(),
            ),
          ],
        ),
      ),
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
