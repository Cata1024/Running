import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/territory_tokens.dart';
import '../../../../core/widgets/aero_widgets.dart';

class TerritorySection extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>?> territoryAsync;

  const TerritorySection({super.key, required this.territoryAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AeroSurface(
      level: AeroLevel.subtle,
      padding: const EdgeInsets.all(TerritoryTokens.space16),
      child: territoryAsync.when(
        data: (doc) {
          final areaKm2 = doc?['totalAreaM2'] != null
              ? (doc!['totalAreaM2'] as num) / 1e6
              : 0.0;
          final sectors = (doc?['tilesClaimed'] as num?)?.toInt() ?? 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.terrain, color: theme.colorScheme.tertiary),
                  const SizedBox(width: TerritoryTokens.space8),
                  Text(
                    'Territorio conquistado',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TerritoryTokens.space12),
              Text(
                areaKm2 > 0
                    ? 'Cobertura aprox. de ${areaKm2.toStringAsFixed(2)} km²'
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
            ],
          );
        },
        loading: () => const SizedBox(
          height: 64,
          child: Center(child: CircularProgressIndicator()),
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
