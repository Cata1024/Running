import 'package:flutter/material.dart';

import '../../../../core/design_system/territory_tokens.dart';
import '../../../../core/widgets/aero_widgets.dart';

class GoalSection extends StatelessWidget {
  final String goal;

  const GoalSection({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AeroSurface(
      level: AeroLevel.ghost,
      padding: const EdgeInsets.all(TerritoryTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Objetivo personal',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TerritoryTokens.space8),
          Text(
            goal,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
