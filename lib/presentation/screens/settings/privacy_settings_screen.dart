import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_widgets.dart';
import '../../../domain/services/firebase_enterprise_service.dart';
import '../../providers/app_providers.dart';
import '../../../data/repositories/auth_repository.dart' show authRepositoryProvider;
import 'home_filter_settings_screen.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidad y Seguridad'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(TerritoryTokens.space16),
        children: [
          // Explicación
          AeroSurface(
            level: AeroLevel.subtle,
            padding: const EdgeInsets.all(TerritoryTokens.space16),
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: TerritoryTokens.space12),
                Expanded(
                  child: Text(
                    'Controla quién puede ver tu información y cómo se usa.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space24),

          // Visibilidad del perfil
          AeroSurface(
            level: AeroLevel.medium,
            padding: const EdgeInsets.all(TerritoryTokens.space16),
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visibilidad',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TerritoryTokens.space16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Perfil Público'),
                  subtitle: Text(
                    settings.publicProfile
                        ? 'Otros usuarios pueden ver tu perfil y estadísticas'
                        : 'Solo tú puedes ver tu información',
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(TerritoryTokens.space8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                    ),
                    child: Icon(
                      settings.publicProfile ? Icons.public : Icons.lock,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  value: settings.publicProfile,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setPublicProfile(value);
                  },
                ),
                if (settings.publicProfile) ...[
                  const Divider(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56),
                    child: AeroSurface(
                      level: AeroLevel.subtle,
                      padding: const EdgeInsets.all(TerritoryTokens.space12),
                      borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: TerritoryTokens.space8),
                          Expanded(
                            child: Text(
                              'Otros usuarios podrán ver tu nombre, avatar, nivel y estadísticas generales.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space24),

          // Ubicación
          AeroSurface(
            level: AeroLevel.medium,
            padding: const EdgeInsets.all(TerritoryTokens.space16),
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ubicación',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TerritoryTokens.space16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Compartir Ubicación en Vivo'),
                  subtitle: Text(
                    settings.shareLocationLive
                        ? 'Tu ubicación se comparte durante carreras activas'
                        : 'Tu ubicación solo se guarda localmente',
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(TerritoryTokens.space8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  value: settings.shareLocationLive,
                  onChanged: (value) {
                    if (value) {
                      _showLocationWarning(context, ref);
                    } else {
                      ref.read(settingsProvider.notifier).setShareLocationLive(false);
                    }
                  },
                ),
                const Divider(height: 32),
                // Filtro de hogar
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(TerritoryTokens.space8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                    ),
                    child: Icon(
                      Icons.home_outlined,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  title: const Text('Filtro de Hogar'),
                  subtitle: Text(
                    settings.homeFilterEnabled && settings.homeLatitude != null
                        ? 'Configurado (${settings.homeRadiusMeters.toInt()}m)'
                        : 'Oculta tu ubicación de hogar en mapas públicos',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeFilterSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space24),

          // Datos y Analytics
          AeroSurface(
            level: AeroLevel.medium,
            padding: const EdgeInsets.all(TerritoryTokens.space16),
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datos y Analytics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TerritoryTokens.space16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Permitir Analytics'),
                  subtitle: const Text('Ayúdanos a mejorar la app compartiendo datos de uso anónimos'),
                  secondary: Container(
                    padding: const EdgeInsets.all(TerritoryTokens.space8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                    ),
                    child: Icon(
                      Icons.analytics,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  value: settings.allowAnalytics,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setAllowAnalytics(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space24),

          // Acciones de datos
          AeroSurface(
            level: AeroLevel.medium,
            padding: const EdgeInsets.all(TerritoryTokens.space20),
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de Datos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TerritoryTokens.space16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showExportDataDialog(context, ref),
                    icon: const Icon(Icons.download),
                    label: const Text('Exportar mis datos'),
                  ),
                ),
                const SizedBox(height: TerritoryTokens.space12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteDataDialog(context, ref),
                    icon: const Icon(Icons.delete_forever),
                    label: Text(
                      'Solicitar eliminación de datos',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space16),

          // Políticas
          Padding(
            padding: const EdgeInsets.all(TerritoryTokens.space8),
            child: Column(
              children: [
                TextButton.icon(
                  onPressed: () => _openPrivacyPolicy(context),
                  icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                  label: const Text('Política de Privacidad'),
                ),
                TextButton.icon(
                  onPressed: () => _openTermsOfService(context),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Términos de Servicio'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationWarning(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.location_on, size: 48),
        title: const Text('Compartir Ubicación en Vivo'),
        content: const Text(
          'Esta función permitirá que personas autorizadas vean tu ubicación en tiempo real durante tus carreras.\n\n¿Estás seguro de que deseas activarla?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setShareLocationLive(true);
              Navigator.pop(context);
            },
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }

  void _showExportDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.download, size: 48),
        title: const Text('Exportar Datos'),
        content: const Text(
          'Recibirás un email con un archivo JSON conteniendo toda tu información: carreras, estadísticas, configuraciones y más.\n\nEsto puede tardar algunos minutos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => _exportUserData(context, ref),
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning, size: 48, color: Theme.of(context).colorScheme.error),
        title: const Text('Eliminar Datos'),
        content: const Text(
          '⚠️ ADVERTENCIA: Esta acción eliminará permanentemente:\n\n• Todas tus carreras\n• Estadísticas y logros\n• Configuraciones\n• Cuenta de usuario\n\nEsta acción NO se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => _deleteUserData(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );
  }
  
  // Helper methods
  
  Future<void> _openPrivacyPolicy(BuildContext context) async {
    const url = 'https://territoryrun.app/privacy';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la política de privacidad')),
        );
      }
    }
  }
  
  Future<void> _openTermsOfService(BuildContext context) async {
    const url = 'https://territoryrun.app/terms';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir los términos de servicio')),
        );
      }
    }
  }
  
  FirebaseEnterpriseService _enterpriseService(WidgetRef ref) {
    return FirebaseEnterpriseService(
      authRepository: ref.read(authRepositoryProvider),
      apiService: ref.read(apiServiceProvider),
    );
  }

  Future<void> _exportUserData(BuildContext context, WidgetRef ref) async {
    final service = _enterpriseService(ref);
    
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario no autenticado')),
          );
        }
        return;
      }
      
      if (!context.mounted) return;
      Navigator.pop(context); // Cerrar dialog de confirmación
      
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(
                  child: Text('Preparando exportación...\nEsto puede tardar un momento.'),
                ),
              ],
            ),
          ),
        ),
      );
      
      // Llamar servicio Enterprise para exportar datos
      final result = await service.exportUserData(user.id);
      final downloadUrl = result['downloadUrl'] as String;
      final fileSize = result['fileSize'] as String;
      
      if (context.mounted) {
        Navigator.pop(context); // Cerrar loading
        
        // Mostrar dialog con link de descarga
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, size: 64, color: Colors.green),
            title: const Text('✅ Exportación Lista'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tus datos están listos para descargar.\n',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text('Tamaño: $fileSize'),
                const SizedBox(height: 8),
                const Text(
                  '⏰ El link estará disponible por 24 horas.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(downloadUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar Mis Datos'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } on FirebaseEnterpriseException catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: $e')),
        );
      }
    }
  }
  
  Future<void> _deleteUserData(BuildContext context, WidgetRef ref) async {
    final service = _enterpriseService(ref);
    
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario no autenticado')),
          );
        }
        return;
      }
      
      if (!context.mounted) return;
      Navigator.pop(context); // Cerrar dialog de confirmación
      
      // Solicitar re-autenticación por seguridad
      final password = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _ReauthDialog(),
      );
      
      if (password == null || password.isEmpty) {
        // Usuario canceló
        return;
      }
      
      if (!context.mounted) return;
      
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(
                  child: Text('Eliminando cuenta y datos...\nEsto puede tardar un momento.'),
                ),
              ],
            ),
          ),
        ),
      );
      
      // Re-autenticar usuario
      await service.reauthenticateUser(password);
      
      // Eliminar datos de Firestore y Storage antes de la cuenta
      await service.deleteUserDataFromFirestore(user.id);
      
      // Eliminar cuenta de Firebase Auth
      // Esto dispara Firebase Extension "delete-user-data" si está configurada
      await service.deleteUserAccount();
      
      // Éxito - redirigir a pantalla de bienvenida
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Cerrar loading
        
        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cuenta eliminada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Redirigir a welcome
        GoRouter.of(context).go('/welcome');
      }
      
    } on FirebaseEnterpriseException catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Cerrar loading
        
        if (e.code == 'wrong-password') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Contraseña incorrecta. Inténtalo de nuevo.'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (e.code == 'requires-recent-login') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Por seguridad, cierra sesión y vuelve a intentarlo.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Dialog para re-autenticación
class _ReauthDialog extends StatefulWidget {
  @override
  State<_ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends State<_ReauthDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      icon: Icon(
        Icons.lock_outlined,
        size: 48,
        color: theme.colorScheme.error,
      ),
      title: const Text('Confirmar Identidad'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Por seguridad, confirma tu contraseña para continuar con la eliminación.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.key),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                Navigator.of(context).pop(value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final password = _passwordController.text;
            if (password.isNotEmpty) {
              Navigator.of(context).pop(password);
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
