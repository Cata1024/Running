import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_widgets.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _packageInfo = info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(TerritoryTokens.space16),
        children: [
          // Logo y versión
          AeroSurface(
            level: AeroLevel.medium,
            padding: const EdgeInsets.all(TerritoryTokens.space32),
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
            child: Column(
              children: [
                // Logo/Icono
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.directions_run,
                    size: 60,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: TerritoryTokens.space24),
                Text(
                  'Territory Run',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TerritoryTokens.space8),
                if (_packageInfo != null) ...[
                  Text(
                    'Versión ${_packageInfo!.version} (${_packageInfo!.buildNumber})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else ...[
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
                const SizedBox(height: TerritoryTokens.space8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TerritoryTokens.space12,
                    vertical: TerritoryTokens.space4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(TerritoryTokens.radiusPill),
                  ),
                  child: Text(
                    'BETA',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space24),

          // Descripción
          AeroSurface(
            level: AeroLevel.subtle,
            padding: const EdgeInsets.all(TerritoryTokens.space16),
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
            child: Text(
              'Conquista territorio con cada kilómetro. Tu ciudad es tu campo de juego.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: TerritoryTokens.space24),

          // Enlaces
          AeroSurface(
            level: AeroLevel.medium,
            padding: const EdgeInsets.all(TerritoryTokens.space8),
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
            child: Column(
              children: [
                _LinkTile(
                  icon: Icons.description_outlined,
                  title: 'Términos de Servicio',
                  onTap: () => _openUrl('https://territoryrun.com/terms'),
                ),
                const Divider(height: 1),
                _LinkTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Política de Privacidad',
                  onTap: () => _openUrl('https://territoryrun.com/privacy'),
                ),
                const Divider(height: 1),
                _LinkTile(
                  icon: Icons.help_outline,
                  title: 'Centro de Ayuda',
                  onTap: () => _openUrl('https://territoryrun.com/help'),
                ),
                const Divider(height: 1),
                _LinkTile(
                  icon: Icons.bug_report_outlined,
                  title: 'Reportar un Problema',
                  onTap: () => _openUrl('mailto:support@territoryrun.com?subject=Reporte de Problema'),
                ),
                const Divider(height: 1),
                _LinkTile(
                  icon: Icons.star_outline,
                  title: 'Calificar en la Tienda',
                  onTap: () => _rateApp(),
                ),
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space24),

          // Créditos
          AeroSurface(
            level: AeroLevel.medium,
            padding: const EdgeInsets.all(TerritoryTokens.space20),
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Créditos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TerritoryTokens.space16),
                const _CreditRow(
                  title: 'Desarrollo',
                  value: 'Territory Run Team',
                ),
                const SizedBox(height: TerritoryTokens.space8),
                const _CreditRow(
                  title: 'Diseño',
                  value: 'Material Design 3',
                ),
                const SizedBox(height: TerritoryTokens.space8),
                _CreditRow(
                  title: 'Framework',
                  value: 'Flutter ${_getFlutterVersion()}',
                ),
                const SizedBox(height: TerritoryTokens.space8),
                const _CreditRow(
                  title: 'Mapas',
                  value: 'Google Maps Platform',
                ),
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space24),

          // Licencias
          Center(
            child: TextButton.icon(
              onPressed: () {
                showLicensePage(
                  context: context,
                  applicationName: 'Territory Run',
                  applicationVersion: _packageInfo?.version ?? '',
                  applicationIcon: Icon(
                    Icons.directions_run,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                );
              },
              icon: const Icon(Icons.code, size: 18),
              label: const Text('Licencias de Código Abierto'),
            ),
          ),
          const SizedBox(height: TerritoryTokens.space32),

          // Footer
          Center(
            child: Column(
              children: [
                Text(
                  '© ${DateTime.now().year} Territory Run',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TerritoryTokens.space4),
                Text(
                  'Hecho con ❤️ para corredores',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space16),
        ],
      ),
    );
  }

  Future<void> _openUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir: $urlString')),
        );
      }
    }
  }

  Future<void> _rateApp() async {
    const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.territoryrun.app';
    const String appStoreUrl = 'https://apps.apple.com/app/territory-run/id123456789';
    
    // Detectar plataforma y usar la URL correspondiente
    String storeUrl;
    if (Platform.isIOS) {
      storeUrl = appStoreUrl;
    } else if (Platform.isAndroid) {
      storeUrl = playStoreUrl;
    } else {
      // Fallback para otras plataformas
      storeUrl = playStoreUrl;
    }
    
    await _openUrl(storeUrl);
  }

  String _getFlutterVersion() {
    // En producción esto vendría de package_info o build config
    return '3.24+';
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(TerritoryTokens.space8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
        ),
        child: Icon(icon, size: 20),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _CreditRow extends StatelessWidget {
  final String title;
  final String value;

  const _CreditRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
