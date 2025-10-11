import 'package:flutter/material.dart';

class LevelCard extends StatelessWidget {
  final int level;
  final double progress;
  final int experience;
  final int nextLevelExperience;

  const LevelCard({
    super.key,
    required this.level,
    required this.progress,
    required this.experience,
    required this.nextLevelExperience,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Nivel $level', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, minHeight: 8),
            const SizedBox(height: 8),
            Text(
              '$experience / $nextLevelExperience XP',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
