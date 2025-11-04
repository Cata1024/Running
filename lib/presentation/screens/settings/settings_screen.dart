import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/aero_surface.dart';
import '../../providers/app_providers.dart';
import 'language_settings_screen.dart';
import 'units_settings_screen.dart';
import 'notifications_settings_screen.dart';
import 'gps_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  
  String _getGpsAccuracyLabel(String accuracy) {
    switch (accuracy) {
      case 'low':
        return 'Baja';
      case 'balanced':
        return 'Equilibrada';
      case 'high':
        return 'Alta';
      default:
        return 'Equilibrada';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    
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
            AeroSurface(
              level: AeroLevel.medium,
              padding: const EdgeInsets.all(TerritoryTokens.space24),
              borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
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
                    subtitle: settings.language == 'es' ? 'Español' : 'English',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.notifications,
                    title: 'Notificaciones',
                    subtitle: settings.notificationsEnabled ? 'Activadas' : 'Desactivadas',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsSettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Running Settings
            AeroSurface(
              level: AeroLevel.medium,
              padding: const EdgeInsets.all(TerritoryTokens.space24),
              borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
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
                    subtitle: settings.units == 'metric' ? 'Kilómetros' : 'Millas',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UnitsSettingsScreen()),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.gps_fixed,
                    title: 'GPS',
                    subtitle: 'Precisión: ${_getGpsAccuracyLabel(settings.gpsAccuracy)}',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GpsSettingsScreen()),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.timer,
                    title: 'Auto Pausa',
                    subtitle: 'Pausar automáticamente cuando te detienes',
                    trailing: Switch(
                      value: settings.autoPauseEnabled,
                      onChanged: (value) {
                        ref.read(settingsProvider.notifier).toggleAutoPause(value);
                      },
                    ),
                    onTap: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Privacy & Security
            AeroSurface(
              level: AeroLevel.medium,
              padding: const EdgeInsets.all(TerritoryTokens.space24),
              borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
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
                    icon: Icons.security,
                    title: 'Privacidad',
                    subtitle: 'Perfil, ubicación y datos',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // About
            AeroSurface(
              level: AeroLevel.medium,
              padding: const EdgeInsets.all(TerritoryTokens.space24),
              borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
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
                    onTap: () async {
                      final uri = Uri.parse('https://google.com/support');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.star_rate,
                    title: 'Calificar App',
                    subtitle: 'Danos tu opinión en la tienda',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final InAppReview inAppReview = InAppReview.instance;
                      if (await inAppReview.isAvailable()) {
                        inAppReview.requestReview();
                      }
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.info,
                    title: 'Acerca de',
                    subtitle: 'Versión, licencias y más',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
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
    void selectTheme(AppThemeMode mode) {
      ref.read(themeProvider.notifier).setTheme(mode);
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<AppThemeMode>(
              segments: const [
                ButtonSegment(
                  value: AppThemeMode.system,
                  label: Text('Sistema'),
                  icon: Icon(Icons.settings_suggest_outlined),
                ),
                ButtonSegment(
                  value: AppThemeMode.light,
                  label: Text('Claro'),
                  icon: Icon(Icons.wb_sunny_outlined),
                ),
                ButtonSegment(
                  value: AppThemeMode.dark,
                  label: Text('Oscuro'),
                  icon: Icon(Icons.nightlight_round),
                ),
              ],
              selected: {currentTheme},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) return;
                selectTheme(selection.first);
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
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
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
