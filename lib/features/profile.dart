import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/services.dart';

class ProfilePage extends ConsumerWidget {
	const ProfilePage({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final profileAsync = ref.watch(currentUserProfileProvider);

		return Scaffold(
			appBar: AppBar(title: const Text('Perfil')),
			body: profileAsync.when(
				data: (profile) {
					if (profile == null) {
						return _emptyState(context);
					}
					final cs = Theme.of(context).colorScheme;
					return SingleChildScrollView(
						padding: const EdgeInsets.all(16),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Row(
									children: [
										CircleAvatar(
											radius: 32,
											backgroundColor: cs.primaryContainer,
											backgroundImage: profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
											child: profile.photoUrl == null
													? Icon(Icons.person, color: cs.onPrimaryContainer, size: 32)
													: null,
										),
										const SizedBox(width: 16),
										Expanded(
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													Text(profile.displayName, style: Theme.of(context).textTheme.titleLarge),
													Text(profile.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
												],
											),
										),
									],
								),

								const SizedBox(height: 16),
								_levelCard(context, profile.level, profile.levelProgress, profile.experience, profile.nextLevelExperience),

								const SizedBox(height: 16),
								_statsGrid(context, profile.totalRuns, profile.totalDistance, profile.totalTime, profile.averagePace, profile.averageSpeed),

								const SizedBox(height: 16),
								Text('Logros', style: Theme.of(context).textTheme.titleMedium),
								const SizedBox(height: 8),
								Wrap(
									spacing: 8,
									runSpacing: 8,
									children: profile.achievements.isNotEmpty
											? profile.achievements.map((a) => Chip(label: Text(a))).toList()
											: [Text('Aún no hay logros', style: TextStyle(color: cs.onSurfaceVariant))],
								),
							],
						),
					);
				},
				loading: () => const Center(child: CircularProgressIndicator()),
				error: (e, st) => Center(child: Text('Error cargando perfil')),
			),
		);
	}

	Widget _emptyState(BuildContext context) {
		final cs = Theme.of(context).colorScheme;
		return Center(
			child: Padding(
				padding: const EdgeInsets.all(24.0),
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Icon(Icons.person_off, size: 48, color: cs.onSurfaceVariant),
						const SizedBox(height: 12),
						const Text('No hay información de perfil'),
					],
				),
			),
		);
	}

	Widget _levelCard(BuildContext context, int level, double progress, int xp, int nextLevelXp) {
		final cs = Theme.of(context).colorScheme;
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16.0),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Row(
							children: [
								Icon(Icons.emoji_events, color: cs.primary),
								const SizedBox(width: 8),
								Text('Nivel $level', style: Theme.of(context).textTheme.titleMedium),
							],
						),
						const SizedBox(height: 8),
						LinearProgressIndicator(value: progress, minHeight: 8),
						const SizedBox(height: 8),
						Text('$xp / $nextLevelXp XP', style: Theme.of(context).textTheme.bodySmall),
					],
				),
			),
		);
	}

	Widget _statsGrid(BuildContext context, int totalRuns, double totalDistance, int totalTime, double avgPace, double avgSpeed) {
		final items = [
			_StatItem(icon: Icons.directions_run, label: 'Carreras', value: '$totalRuns'),
			_StatItem(icon: Icons.route, label: 'Distancia', value: '${totalDistance.toStringAsFixed(1)} km'),
			_StatItem(icon: Icons.timelapse, label: 'Tiempo', value: _formatDuration(Duration(seconds: totalTime))),
			_StatItem(icon: Icons.speed, label: 'Ritmo prom', value: avgPace > 0 ? '${avgPace.toStringAsFixed(1)} min/km' : '--'),
			_StatItem(icon: Icons.directions_run, label: 'Velocidad', value: '${avgSpeed.toStringAsFixed(1)} km/h'),
		];
		return GridView.builder(
			shrinkWrap: true,
			physics: const NeverScrollableScrollPhysics(),
			gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.2),
			itemCount: items.length,
			itemBuilder: (context, i) => Card(
				child: Padding(
					padding: const EdgeInsets.all(12.0),
					child: Row(
						children: [
							Icon(items[i].icon),
							const SizedBox(width: 12),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									mainAxisAlignment: MainAxisAlignment.center,
									children: [
										Text(items[i].value, style: Theme.of(context).textTheme.titleMedium),
										Text(items[i].label, style: Theme.of(context).textTheme.bodySmall),
									],
								),
							),
						],
					),
				),
			),
		);
	}

	String _formatDuration(Duration d) {
		final h = d.inHours;
		final m = d.inMinutes % 60;
		final s = d.inSeconds % 60;
		if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
		return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
	}
}

class _StatItem {
	final IconData icon;
	final String label;
	final String value;
	_StatItem({required this.icon, required this.label, required this.value});
}
