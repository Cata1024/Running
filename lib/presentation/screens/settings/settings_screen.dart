import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: AppTheme.paddingMedium,
        child: Column(
          children: [
            // App Settings
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aplicación',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _SettingsTile(
                    icon: Icons.palette,
                    title: 'Tema',
                    subtitle: 'Claro, oscuro o automático',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showThemeDialog(context, ref);
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.language,
                    title: 'Idioma',
                    subtitle: 'Español',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Language settings
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.notifications,
                    title: 'Notificaciones',
                    subtitle: 'Configurar alertas y recordatorios',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Notifications settings
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Running Settings
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Carrera',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _SettingsTile(
                    icon: Icons.straighten,
                    title: 'Unidades',
                    subtitle: 'Kilómetros y metros',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Units settings
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.gps_fixed,
                    title: 'GPS',
                    subtitle: 'Precisión y configuración',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // GPS settings
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.timer,
                    title: 'Auto Pausa',
                    subtitle: 'Pausar automáticamente cuando te detienes',
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {
                        // Toggle auto pause
                      },
                    ),
                    onTap: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Privacy & Security
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacidad y Seguridad',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _SettingsTile(
                    icon: Icons.visibility,
                    title: 'Perfil Público',
                    subtitle: 'Permitir que otros vean tu perfil',
                    trailing: Switch(
                      value: false,
                      onChanged: (value) {
                        // Toggle public profile
                      },
                    ),
                    onTap: null,
                  ),
                  _SettingsTile(
                    icon: Icons.location_on,
                    title: 'Compartir Ubicación',
                    subtitle: 'Durante carreras en vivo',
                    trailing: Switch(
                      value: false,
                      onChanged: (value) {
                        // Toggle location sharing
                      },
                    ),
                    onTap: null,
                  ),
                  _SettingsTile(
                    icon: Icons.security,
                    title: 'Cambiar Contraseña',
                    subtitle: 'Actualizar tu contraseña',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Change password
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // About
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acerca de',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _SettingsTile(
                    icon: Icons.help,
                    title: 'Ayuda y Soporte',
                    subtitle: 'FAQs y contacto',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Help and support
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.star_rate,
                    title: 'Calificar App',
                    subtitle: 'Danos tu opinión en la tienda',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Rate app
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.info,
                    title: 'Versión',
                    subtitle: '1.0.0 (Beta)',
                    trailing: null,
                    onTap: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(themeProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Sistema'),
              leading: Radio<String>(
                value: 'system',
                groupValue: currentTheme == AppThemeMode.system ? 'system' : 
                           currentTheme == AppThemeMode.light ? 'light' : 'dark',
                onChanged: (value) {
                  // TODO: Update theme
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                // TODO: Update theme to system
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Claro'),
              leading: Radio<String>(
                value: 'light',
                groupValue: currentTheme == AppThemeMode.system ? 'system' : 
                           currentTheme == AppThemeMode.light ? 'light' : 'dark',
                onChanged: (value) {
                  // TODO: Update theme
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                // TODO: Update theme to light
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Oscuro'),
              leading: Radio<String>(
                value: 'dark',
                groupValue: currentTheme == AppThemeMode.system ? 'system' : 
                           currentTheme == AppThemeMode.light ? 'light' : 'dark',
                onChanged: (value) {
                  // TODO: Update theme
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                // TODO: Update theme to dark
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
