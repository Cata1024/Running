import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_widgets.dart';
import '../../providers/settings_provider.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentLanguage = ref.watch(settingsProvider.select((s) => s.language));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Idioma'),
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
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: TerritoryTokens.space12),
                Expanded(
                  child: Text(
                    'Selecciona el idioma de la aplicación',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space24),

          // Opciones de idioma
          AeroSurface(
            level: AeroLevel.medium,
            padding: const EdgeInsets.all(TerritoryTokens.space8),
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
            child: Column(
              children: [
                _LanguageOption(
                  flag: '🇪🇸',
                  name: 'Español',
                  subtitle: 'Spanish',
                  value: 'es',
                  currentLanguage: currentLanguage,
                  onTap: () => ref.read(settingsProvider.notifier).setLanguage('es'),
                ),
                const Divider(height: 1),
                _LanguageOption(
                  flag: '🇺🇸',
                  name: 'English',
                  subtitle: 'Inglés',
                  value: 'en',
                  currentLanguage: currentLanguage,
                  onTap: () => ref.read(settingsProvider.notifier).setLanguage('en'),
                ),
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space16),

          // Nota
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TerritoryTokens.space8),
            child: Text(
              'Más idiomas estarán disponibles próximamente',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String name;
  final String subtitle;
  final String value;
  final String currentLanguage;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.name,
    required this.subtitle,
    required this.value,
    required this.currentLanguage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = value == currentLanguage;

    return ListTile(
      leading: Text(
        flag,
        style: const TextStyle(fontSize: 32),
      ),
      title: Text(
        name,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            )
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
      ),
    );
  }
}
