import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/providers/run_state_provider.dart';
import 'glass_panel.dart';
import 'route_picker_sheet.dart';

class RunControlDock extends ConsumerWidget {
  final RunState runState;
  final bool wrapInPanel;

  const RunControlDock({
    super.key,
    required this.runState,
    this.wrapInPanel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runNotifier = ref.read(runStateProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    Widget buildPrimaryButton({
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
      Color? background,
      Color? foreground,
    }) {
      return Expanded(
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: background ?? colorScheme.primary,
            foregroundColor: foreground ?? colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      );
    }

    Widget buildSecondaryButton({
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
    }) {
      return Expanded(
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    Future<void> openRoutePicker() async {
      final result = await showModalBottomSheet<RoutePickerSelection>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => const RoutePickerSheet(),
      );

      if (result == null) return;
      if (result.clearSelection) {
        runNotifier.clearPlannedRoute();
      } else if (result.route != null) {
        runNotifier.selectPlannedRoute(result.route!);
      }
    }

    Widget content;

    if (!runState.locationPermissionGranted) {
      content = Row(
        children: [
          buildPrimaryButton(
            icon: Icons.location_searching,
            label: 'Permitir ubicación',
            onPressed: () => runNotifier.startRun(),
          ),
        ],
      );
    } else if (!runState.isRunning) {
      content = Row(
        children: [
          buildPrimaryButton(
            icon: Icons.play_arrow,
            label: 'Iniciar sesión',
            onPressed: () => runNotifier.startRun(),
          ),
          const SizedBox(width: 12),
          buildSecondaryButton(
            icon: Icons.route,
            label: 'Rutas',
            onPressed: openRoutePicker,
          ),
        ],
      );
    } else if (runState.isPaused) {
      content = Row(
        children: [
          buildPrimaryButton(
            icon: Icons.play_arrow,
            label: 'Reanudar',
            onPressed: () => runNotifier.resumeRun(),
          ),
          const SizedBox(width: 12),
          buildSecondaryButton(
            icon: Icons.stop,
            label: 'Finalizar',
            onPressed: () => runNotifier.stopRun(),
          ),
          const SizedBox(width: 12),
          buildSecondaryButton(
            icon: Icons.refresh,
            label: 'Reiniciar',
            onPressed: () => runNotifier.resetRun(),
          ),
        ],
      );
    } else {
      content = Row(
        children: [
          buildPrimaryButton(
            icon: Icons.pause,
            label: 'Pausar',
            onPressed: () => runNotifier.pauseRun(),
          ),
          const SizedBox(width: 12),
          buildSecondaryButton(
            icon: Icons.stop,
            label: 'Finalizar',
            onPressed: () => runNotifier.stopRun(),
          ),
        ],
      );
    }

    final plannedRoute = runState.plannedRoute;

    Widget body = content;

    if (plannedRoute != null) {
      final theme = Theme.of(context);
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plannedRoute.title?.isNotEmpty == true
                            ? plannedRoute.title!
                            : 'Ruta planificada',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${plannedRoute.distanceKm.toStringAsFixed(1)} km · ${(plannedRoute.durationSec / 60).round()} min',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar ruta planificada',
                  icon: Icon(Icons.close,
                      color: theme.colorScheme.onPrimaryContainer),
                  onPressed: runNotifier.clearPlannedRoute,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      );
    }

    if (!wrapInPanel) {
      return body;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassPanel(
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.all(16),
        child: body,
      ),
    );
  }
}
