import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/route_model.dart';
import '../../../services/routes/routes_service.dart';
import '../../../shared/services.dart' as shared_services;

class RoutePickerSelection {
  final RouteModel? route;
  final bool clearSelection;

  const RoutePickerSelection._({this.route, this.clearSelection = false});

  factory RoutePickerSelection.select(RouteModel route) =>
      RoutePickerSelection._(route: route);

  static const RoutePickerSelection cleared =
      RoutePickerSelection._(clearSelection: true);
}

class RoutePickerSheet extends ConsumerWidget {
  const RoutePickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(shared_services.currentUserProvider);

    if (user == null) {
      return _buildScaffold(
        context,
        child: const _RoutePickerMessage(
          icon: Icons.person_off,
          title: 'Inicia sesión para ver tus rutas',
          subtitle:
              'Necesitas iniciar sesión para seleccionar rutas guardadas.',
        ),
      );
    }

    final routesAsync = ref.watch(userRoutesProvider(user.uid));

    return routesAsync.when(
      data: (routes) {
        if (routes.isEmpty) {
          return _buildScaffold(
            context,
            child: const _RoutePickerMessage(
              icon: Icons.route_outlined,
              title: 'Sin rutas guardadas',
              subtitle:
                  'Guarda tus recorridos para reutilizarlos en futuras sesiones.',
            ),
          );
        }

        return _buildScaffold(
          context,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: routes.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(Icons.highlight_off_outlined),
                  title: const Text('Sin ruta planificada'),
                  subtitle:
                      const Text('Comienza sin seguir un recorrido guardado'),
                  onTap: () =>
                      Navigator.of(context).pop(RoutePickerSelection.cleared),
                );
              }

              final route = routes[index - 1];
              return _RouteListTile(
                route: route,
                onTap: () => Navigator.of(context)
                    .pop(RoutePickerSelection.select(route)),
              );
            },
          ),
        );
      },
      loading: () => _buildScaffold(
        context,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _buildScaffold(
        context,
        child: _RoutePickerMessage(
          icon: Icons.error_outline,
          title: 'Error cargando rutas',
          subtitle: '$error',
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, {required Widget child}) {
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height * 0.75;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _RouteListTile extends StatelessWidget {
  final RouteModel route;
  final VoidCallback onTap;

  const _RouteListTile({required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final distance = '${route.distanceKm.toStringAsFixed(1)} km';
    final durationMinutes = (route.durationSec / 60).round();
    final duration = '$durationMinutes min';
    final createdAt = route.createdAt;
    final formattedDate =
        '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: const Icon(Icons.route),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.title?.isNotEmpty == true
                          ? route.title!
                          : 'Ruta sin título',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$distance · $duration',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Última vez: $formattedDate',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutePickerMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RoutePickerMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  static final RegExp _linkRegExp = RegExp(r'https?:\/\/\S+');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final link = _extractFirstLink(subtitle);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SelectableText(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (link != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enlace copiado al portapapeles'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copiar enlace'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _extractFirstLink(String text) {
    final match = _linkRegExp.firstMatch(text);
    return match?.group(0);
  }
}
