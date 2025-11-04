import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_widgets.dart';
import '../../providers/settings_provider.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(TerritoryTokens.space16),
        children: [
          // Notificaciones generales
          AeroSurface(
            level: AeroLevel.medium,
            padding: const EdgeInsets.all(TerritoryTokens.space16),
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'General',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TerritoryTokens.space16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Habilitar notificaciones'),
                  subtitle: const Text('Recibir alertas y recordatorios'),
                  secondary: Container(
                    padding: const EdgeInsets.all(TerritoryTokens.space8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                    ),
                    child: Icon(
                      Icons.notifications,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  value: settings.notificationsEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleNotifications(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space24),

          // Notificaciones específicas
          AeroSurface(
            level: AeroLevel.medium,
            padding: const EdgeInsets.all(TerritoryTokens.space16),
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipos de Notificaciones',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TerritoryTokens.space16),
                
                // Recordatorios de carrera
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Recordatorios de carrera'),
                  subtitle: Text(
                    settings.runRemindersEnabled
                        ? 'Diariamente a las ${settings.runReminderTime}'
                        : 'Desactivado',
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(TerritoryTokens.space8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                    ),
                    child: Icon(
                      Icons.alarm,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  value: settings.runRemindersEnabled,
                  onChanged: settings.notificationsEnabled
                      ? (value) {
                          ref.read(settingsProvider.notifier).toggleRunReminders(value);
                        }
                      : null,
                ),
                if (settings.runRemindersEnabled) ...[
                  const SizedBox(height: TerritoryTokens.space8),
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: OutlinedButton.icon(
                      onPressed: () => _selectReminderTime(context, ref, settings.runReminderTime),
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text('Cambiar hora: ${settings.runReminderTime}'),
                    ),
                  ),
                ],
                const Divider(height: 32),

                // Logros y niveles
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Logros y niveles'),
                  subtitle: const Text('Cuando subes de nivel o desbloqueas logros'),
                  secondary: Container(
                    padding: const EdgeInsets.all(TerritoryTokens.space8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  value: settings.achievementNotificationsEnabled,
                  onChanged: settings.notificationsEnabled
                      ? (value) {
                          ref.read(settingsProvider.notifier).toggleAchievementNotifications(value);
                        }
                      : null,
                ),
                const Divider(height: 32),

                // Reporte semanal
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reporte semanal'),
                  subtitle: const Text('Resumen de tu actividad cada semana'),
                  secondary: Container(
                    padding: const EdgeInsets.all(TerritoryTokens.space8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                    ),
                    child: Icon(
                      Icons.insights,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  value: settings.weeklyReportEnabled,
                  onChanged: settings.notificationsEnabled
                      ? (value) {
                          ref.read(settingsProvider.notifier).toggleWeeklyReport(value);
                        }
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: TerritoryTokens.space16),

          // Nota informativa
          if (!settings.notificationsEnabled)
            Padding(
              padding: const EdgeInsets.all(TerritoryTokens.space8),
              child: AeroSurface(
                level: AeroLevel.subtle,
                padding: const EdgeInsets.all(TerritoryTokens.space12),
                borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: TerritoryTokens.space12),
                    Expanded(
                      child: Text(
                        'Las notificaciones están desactivadas. Activa la opción principal para recibir alertas.',
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
      ),
    );
  }

  Future<void> _selectReminderTime(BuildContext context, WidgetRef ref, String currentTime) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      ref.read(settingsProvider.notifier).setRunReminderTime(timeString);
    }
  }
}
