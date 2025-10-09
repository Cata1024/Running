import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home.dart';
import 'glass_panel.dart';

class RunControlDock extends ConsumerWidget {
  final RunState runState;

  const RunControlDock({super.key, required this.runState});

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
            onPressed: () {
              // TODO: abrir selector de rutas
            },
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassPanel(
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }
}
