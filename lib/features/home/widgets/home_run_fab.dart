import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/run_state_provider.dart';

class HomeRunFab extends ConsumerWidget {
  final RunState runState;

  const HomeRunFab({super.key, required this.runState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runNotifier = ref.read(runStateProvider.notifier);

    if (!runState.locationPermissionGranted) {
      return Tooltip(
        message: 'Permisos de ubicación requeridos',
        child: FloatingActionButton(
          onPressed: () => runNotifier.startRun(),
          child: const Icon(Icons.location_searching),
        ),
      );
    }

    if (!runState.isRunning) {
      return FloatingActionButton.extended(
        onPressed: () => runNotifier.startRun(),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Iniciar'),
      );
    }

    if (runState.isPaused) {
      return Wrap(
        spacing: 12,
        children: [
          FloatingActionButton.extended(
            onPressed: () => runNotifier.resumeRun(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Reanudar'),
          ),
          FloatingActionButton(
            heroTag: 'fab-stop',
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            onPressed: () => runNotifier.stopRun(),
            child: const Icon(Icons.stop),
          ),
          FloatingActionButton(
            heroTag: 'fab-reset',
            onPressed: () => runNotifier.resetRun(),
            child: const Icon(Icons.refresh),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      children: [
        FloatingActionButton.extended(
          onPressed: () => runNotifier.pauseRun(),
          icon: const Icon(Icons.pause),
          label: const Text('Pausar'),
        ),
        FloatingActionButton(
          heroTag: 'fab-stop',
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
          onPressed: () => runNotifier.stopRun(),
          child: const Icon(Icons.stop),
        ),
      ],
    );
  }
}
