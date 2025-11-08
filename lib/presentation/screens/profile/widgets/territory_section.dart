import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/design_system/territory_tokens.dart';
import '../../../../core/widgets/aero_widgets.dart';
import '../../../../domain/entities/territory.dart';
import '../../../widgets/animated_scale_button.dart';
import '../../../widgets/pulse_icon.dart';
import '../../territory/territory_map_screen.dart';

class TerritorySection extends StatelessWidget {
  final AsyncValue<Territory?> territoryAsync;

  const TerritorySection({super.key, required this.territoryAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AeroSurface(
      level: AeroLevel.subtle,
      padding: const EdgeInsets.all(TerritoryTokens.space16),
      child: territoryAsync.when(
        data: (territory) {
          final areaKm2 = ((territory?.totalAreaM2) ?? 0.0) / 1e6;
          final sectors = 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PulseIcon(
                    icon: Icons.terrain,
                    color: theme.colorScheme.tertiary,
                    size: 24,
                  ),
                  const SizedBox(width: TerritoryTokens.space8),
                  Expanded(
                    child: Text(
                      'Territorio conquistado',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (areaKm2 > 0)
                    IconButton(
                      icon: const Icon(Icons.map_outlined, size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TerritoryMapScreen(),
                          ),
                        );
                      },
                      tooltip: 'Ver en mapa',
                    ),
                ],
              ),
              const SizedBox(height: TerritoryTokens.space12),
              Text(
                areaKm2 > 0
                    ? 'Cobertura aprox. de ${areaKm2.toStringAsFixed(3)} km²'
                    : 'Aún no has conquistado territorio',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (sectors > 0) ...[
                const SizedBox(height: TerritoryTokens.space8),
                Text(
                  'Sectores capturados: $sectors',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (areaKm2 > 0) ...[
                const SizedBox(height: TerritoryTokens.space12),
                AnimatedScaleButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const TerritoryMapScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOutCubic;
                          final tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          final offsetAnimation = animation.drive(tween);
                          return SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 400),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {}, // Dummy callback (handled by AnimatedScaleButton)
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Ver mapa de territorio'),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => Shimmer.fromColors(
          baseColor: theme.colorScheme.surfaceContainerHighest,
          highlightColor: theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: TerritoryTokens.space8),
                  Container(
                    width: 180,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TerritoryTokens.space12),
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: TerritoryTokens.space8),
              Container(
                width: 150,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        error: (error, _) => Text(
          'No se pudo cargar el territorio',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
