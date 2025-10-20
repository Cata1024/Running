import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  bool _uploading = false;
  late final AnimationController _avatarPulseController;
  bool _fabOpen = false;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '--:--';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _avatarPulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _avatarPulseController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
      if (file == null) return;
      HapticFeedback.selectionClick();
      setState(() => _uploading = true);

      final storageRef =
          FirebaseStorage.instance.ref().child('users/${user.uid}/avatar.jpg');
      final bytes = await file.readAsBytes();
      await storageRef.putData(
          bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await storageRef.getDownloadURL();
      await user.updatePhotoURL(url);
      final api = ref.read(apiServiceProvider);
      await api.patchUserProfile(user.uid, {'photoUrl': url});
      ref.invalidate(userProfileDocProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Foto actualizada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar foto: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentFirebaseUserProvider);
    final profileDocAsync = ref.watch(userProfileDocProvider);
    final territoryDocAsync = ref.watch(userTerritoryDocProvider);
    final runsAsync = ref.watch(userRunsProvider);
    final mapType = ref.watch(mapTypeProvider);
    final mapStyle = ref.watch(mapStyleProvider);

    final profileData = profileDocAsync.value;
    final displayName =
        (profileData?['displayName'] as String?) ?? user?.displayName ?? 'Usuario';
    final email = (profileData?['email'] as String?) ?? user?.email;
    final photoUrl = (profileData?['photoUrl'] as String?) ??
        (profileData?['photoURL'] as String?) ??
        user?.photoURL;

    final colorA = theme.colorScheme.primary;
    final colorB = theme.colorScheme.secondary;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: _buildExpandableFab(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            expandedHeight: 340,
            scrolledUnderElevation: 8,
            flexibleSpace: LayoutBuilder(builder: (context, constraints) {
              final top = constraints.biggest.height;
              final collapsed = top <=
                  kToolbarHeight + MediaQuery.of(context).padding.top + 20;
              return FlexibleSpaceBar(
                centerTitle: true,
                title: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: collapsed ? 1.0 : 0.0,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    CircleAvatar(
                        radius: 14,
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? const Icon(Icons.person, size: 14)
                            : null),
                    const SizedBox(width: 8),
                    Text(displayName,
                        style: theme.textTheme.titleSmall),
                  ]),
                ),
                background: Stack(children: [
                  // background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        colorA.withValues(alpha: 0.18),
                        colorB.withValues(alpha: 0.12)
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                  ),
                  // frosted glass overlay
                  Positioned.fill(
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: const SizedBox())),

                  // animated subtle overlay shapes for premium feel
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 600),
                      opacity: collapsed ? 0.3 : 1,
                      child: Align(
                          alignment: Alignment.topRight,
                          child: Transform.rotate(
                              angle: -0.4,
                              child: Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(120),
                                      gradient: RadialGradient(colors: [
                                        colorB.withValues(alpha: 0.06),
                                        Colors.transparent
                                      ]))))),
                    ),
                  ),

                  // big avatar + details
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        child: Row(children: [
                          _ProfileAvatar(
                            photoUrl: photoUrl,
                            displayName: displayName,
                            uploading: _uploading,
                            onTap: _pickAndUploadAvatar,
                            pulse: _avatarPulseController,
                            outerGradient:
                                LinearGradient(colors: [colorA, colorB]),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(displayName,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800)),
                                  if (email != null)
                                    Text(email,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                                color: onSurfaceVariant)),
                                  const SizedBox(height: 8),
                                  profileDocAsync.when(
                                    data: (data) {
                                      final iso =
                                          data?['lastActivityAt'] as String?;
                                      if (iso == null) {
                                        return const SizedBox.shrink();
                                      }
                                      final dt = DateTime.tryParse(iso);
                                      if (dt == null) {
                                        return const SizedBox.shrink();
                                      }
                                      String fmt(DateTime d) =>
                                          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                                      return Text(
                                          'Última actividad: ${fmt(dt)}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                  color: onSurfaceVariant));
                                    },
                                    loading: () => const SizedBox(
                                        height: 14,
                                        width: 80,
                                        child: LinearProgressIndicator()),
                                    error: (_, __) => const SizedBox.shrink(),
                                  )
                                ]),
                          )
                        ]),
                      ),
                    ),
                  )
                ]),
              );
            }),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppTheme.paddingMedium,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Level badge + progress ring
                    GlassContainer(
                      child: Column(children: [
                        const SizedBox(height: 8),
                        profileDocAsync.when(
                          data: (p) {
                            final distKm =
                                ((p?['totalDistance'] as num?)?.toDouble() ??
                                    0.0);
                            final runs =
                                (p?['totalRuns'] as num?)?.toInt() ?? 0;
                            final percent =
                                (distKm % 50) / 50.0; // progress to next level
                            int level = (distKm ~/ 50) + 1;
                            if (level < 1) level = 1;
                            String title;
                            if (distKm >= 500) {
                              title = 'Leyenda';
                            } else if (distKm >= 250) {
                              title = 'Élite';
                            } else if (distKm >= 100) {
                              title = 'Avanzado';
                            } else if (distKm >= 50) {
                              title = 'Intermedio';
                            } else {
                              title = 'Principiante';
                            }

                            return Row(children: [
                              _RadialProgress(
                                  size: 104,
                                  percent: percent,
                                  level: level,
                                  colors: [colorA, colorB]),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Nivel $level • $title',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 8),
                                      Text(
                                          '$runs carreras • ${distKm.toStringAsFixed(1)} km',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                  color: onSurfaceVariant)),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Tiempo total: ${_formatDuration((p?['totalTime'] as num?)?.toInt() ?? 0)}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: onSurfaceVariant),
                                      ),
                                    ]),
                              )
                            ]);
                          },
                          loading: () => const SizedBox(
                              height: 80,
                              child:
                                  Center(child: CircularProgressIndicator())),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 8),
                      ]),
                    ),

                    const SizedBox(height: 12),

                    // Stats grid with small charts
                    GlassContainer(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mi resumen',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            profileDocAsync.when(
                              data: (p) {
                                final runs =
                                    (p?['totalRuns'] as num?)?.toInt() ?? 0;
                                final distKm = ((p?['totalDistance'] as num?)
                                        ?.toDouble() ??
                                    0.0);
                                final totalSec =
                                    (p?['totalTime'] as num?)?.toInt() ?? 0;

                                final t = territoryDocAsync.value;
                                final areaHa =
                                    (((t?['totalAreaM2'] as num?)?.toDouble() ??
                                                0.0) /
                                            10000.0)
                                        .toStringAsFixed(2);

                                final cards = [
                                  StatCard(
                                    icon: Icons.directions_run,
                                    label: 'Carreras',
                                    value: '$runs',
                                  ),
                                  StatCard(
                                    icon: Icons.route,
                                    label: 'Distancia',
                                    value: '${distKm.toStringAsFixed(1)} km',
                                  ),
                                  StatCard(
                                    icon: Icons.timer,
                                    label: 'Tiempo',
                                    value: _formatDuration(totalSec),
                                  ),
                                  StatCard(
                                    icon: Icons.terrain,
                                    label: 'Territorio',
                                    value: '$areaHa ha',
                                  ),
                                ];

                                final crossAxis =
                                    MediaQuery.of(context).size.width > 700
                                        ? 2
                                        : 1;

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxis,
                                    childAspectRatio: 2.6,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: cards.length,
                                  itemBuilder: (_, index) => cards[index],
                                );
                              },
                              loading: () => const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: LinearProgressIndicator()),
                              error: (_, __) => const Text('No se pudo cargar'),
                            ),
                          ]),
                    ),

                    const SizedBox(height: 12),

                    _DistanceBarChart(runsAsync: runsAsync),

                    const SizedBox(height: 18),

                    _PaceChips(runsAsync: runsAsync),

                    const SizedBox(height: 18),

                    GlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mapa preferido',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          _MapTypeSelector(
                            selected: mapType,
                            onChanged: (type) =>
                                ref.read(mapTypeProvider.notifier).setMapType(type),
                          ),
                          const SizedBox(height: 16),
                          Text('Estilo del mapa',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          _MapStyleSelector(
                            selected: mapStyle,
                            onChanged: (style) => ref
                                .read(mapStyleProvider.notifier)
                                .setStyle(style),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    GlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Recientes',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              TextButton(
                                  onPressed: () => context.go('/history'),
                                  child: const Text('Ver historial')),
                            ],
                          ),
                          runsAsync.when(
                            data: (runs) {
                              if (runs.isEmpty) {
                                return Text('Sin carreras registradas',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(color: onSurfaceVariant));
                              }
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: math.min(runs.length, 5),
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (_, index) {
                                  final run = runs[index];
                                  final distance =
                                      ((run['distanceKm'] as num?)?.toDouble() ??
                                              0.0)
                                          .toStringAsFixed(2);
                                  final date = DateTime.tryParse(
                                      run['startAt'] as String? ?? '');
                                  final pace =
                                      (run['pace'] as String?) ?? '--:--';
                                  return _ProfileRunTile(
                                    title: run['title'] as String? ?? 'Carrera',
                                    subtitle: date != null
                                        ? _formatDate(date)
                                        : 'Fecha desconocida',
                                    distance: distance,
                                    pace: pace,
                                    onTap: () {
                                      final id = run['id'] as String?;
                                      if (id != null) {
                                        context.go('/runs/$id');
                                      }
                                    },
                                  );
                                },
                              );
                            },
                            loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: LinearProgressIndicator()),
                            error: (_, __) => Text('No se pudo cargar',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: onSurfaceVariant)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Actions
                    Column(children: [
                      GlassButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.go('/profile/complete');
                        },
                        isOutlined: true,
                        child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Editar Perfil')
                            ]),
                      ),
                      const SizedBox(height: 12),
                      GlassButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.go('/map');
                        },
                        isOutlined: true,
                        child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.terrain),
                              SizedBox(width: 8),
                              Text('Ver Territorio en Mapa')
                            ]),
                      ),
                      const SizedBox(height: 12),
                      GlassButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Cerrar sesión'),
                              content: const Text(
                                  '¿Seguro que quieres cerrar sesión?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancelar')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Cerrar')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final authService = ref.read(authServiceProvider);
                            await authService.signOut();
                          }
                        },
                        isOutlined: true,
                        backgroundColor: Colors.red.withValues(alpha: 0.10),
                        child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Cerrar Sesión',
                                  style: TextStyle(color: Colors.red))
                            ]),
                      ),
                    ])
                  ]),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildExpandableFab(BuildContext context) {
    final theme = Theme.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (_fabOpen) ...[
        _smallFab(
            icon: Icons.edit,
            label: 'Editar',
            onTap: () => context.go('/profile/complete')),
        const SizedBox(height: 8),
        _smallFab(
            icon: Icons.map, label: 'Mapa', onTap: () => context.go('/map')),
        const SizedBox(height: 8),
      ],
      FloatingActionButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          setState(() => _fabOpen = !_fabOpen);
        },
        backgroundColor: theme.colorScheme.primary,
        child: AnimatedRotation(
            turns: _fabOpen ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 260),
            child: const Icon(Icons.menu)),
      )
    ]);
  }

  Widget _smallFab(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label)
            ]),
          ),
        ),
      ),
      const SizedBox(width: 8),
    ]);
  }
}

class _MapStyleSelector extends StatelessWidget {
  final MapVisualStyle selected;
  final ValueChanged<MapVisualStyle> onChanged;

  const _MapStyleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final options = [
      (MapVisualStyle.automatic, 'Automático', Icons.auto_awesome),
      (MapVisualStyle.light, 'Claro', Icons.wb_sunny_outlined),
      (MapVisualStyle.dark, 'Oscuro', Icons.nightlight_round),
      (MapVisualStyle.off, 'Original', Icons.layers_clear),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final option in options)
          ChoiceChip(
            selected: selected == option.$1,
            onSelected: (_) => onChanged(option.$1),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(option.$3, size: 18),
                const SizedBox(width: 8),
                Text(option.$2),
              ],
            ),
            selectedColor: scheme.primary.withValues(alpha: 0.16),
            backgroundColor: scheme.surface.withValues(alpha: 0.4),
            labelStyle: theme.textTheme.bodyMedium,
            side: BorderSide(
              color: selected == option.$1
                  ? scheme.primary
                  : scheme.outline.withValues(alpha: 0.2),
            ),
          ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? displayName;
  final bool uploading;
  final VoidCallback onTap;
  final AnimationController pulse;
  final Gradient outerGradient;

  const _ProfileAvatar({
    required this.photoUrl,
    required this.displayName,
    required this.uploading,
    required this.onTap,
    required this.pulse,
    required this.outerGradient,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 112;
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final scale = 1 + (pulse.value * 0.02);
        return Transform.scale(
          scale: scale,
          child: Stack(alignment: Alignment.bottomRight, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: outerGradient,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8))
                  ]),
              child: ClipOval(
                child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                        width: size,
                        height: size,
                        color: Colors.white.withValues(alpha: 0.06),
                        child: _avatarImage(size))),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: InkWell(
                onTap: uploading ? null : onTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.28),
                            blurRadius: 8)
                      ]),
                  padding: const EdgeInsets.all(8),
                  child: uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Icon(Icons.camera_alt,
                          size: 16, color: Colors.white),
                ),
              ),
            )
          ]),
        );
      },
    );
  }

  Widget _avatarImage(double size) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Image.network(photoUrl!,
          width: size, height: size, fit: BoxFit.cover);
    }
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            name[0].toUpperCase(),
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    return SizedBox(
        width: size,
        height: size,
        child: Center(
            child: Icon(Icons.person,
                size: size * 0.48,
                color: Colors.white.withValues(alpha: 0.95))));
  }
}

class _RadialProgress extends StatelessWidget {
  final double percent;
  final int level;
  final double size;
  final List<Color> colors;
  const _RadialProgress(
      {this.size = 80,
      required this.percent,
      required this.level,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
              painter: _RadialPainter(percent: percent, colors: colors)),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Lv $level',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('${(percent * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall)
        ]),
      ]),
    );
  }
}

class _RadialPainter extends CustomPainter {
  final double percent;
  final List<Color> colors;
  _RadialPainter({required this.percent, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius - 4, bgPaint);

    if (percent <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius - 4);
    final gradient = SweepGradient(
        colors: colors,
        startAngle: -3.14 / 2,
        endAngle: -3.14 / 2 + 2 * 3.14 * percent);
    final progPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -3.14 / 2, 2 * 3.14 * percent, false, progPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Medal extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool done;
  final Color color;
  const _Medal(
      {required this.icon,
      required this.label,
      required this.done,
      required this.color});

  @override
  State<_Medal> createState() => _MedalState();
}

class _MedalState extends State<_Medal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    if (widget.done) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _Medal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.done && !_controller.isCompleted) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ScaleTransition(
      scale: Tween(begin: 0.98, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticOut)),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface.withValues(alpha: 0.06)),
        child: Column(children: [
          Stack(alignment: Alignment.topCenter, children: [
            // ribbon
            Positioned(
                top: 0,
                child: Container(
                    height: 18,
                    width: 56,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(colors: [
                          widget.color.withValues(alpha: 0.9),
                          widget.color.withValues(alpha: 0.6)
                        ])))),
            CircleAvatar(
                radius: 30,
                backgroundColor: widget.done
                    ? widget.color
                    : widget.color.withValues(alpha: 0.14),
                child: Icon(widget.icon,
                    color: widget.done ? Colors.white : widget.color,
                    size: 28)),
          ]),
          const SizedBox(height: 10),
          Text(widget.label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(widget.done ? 'Completado' : 'Pendiente',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _DistanceBarChart extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> runsAsync;

  const _DistanceBarChart({required this.runsAsync});

  static String _monthLabel(DateTime date) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distancia mensual',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            runsAsync.when(
              data: (runs) {
                final now = DateTime.now();
                final monthStarts = List.generate(
                    6, (index) => DateTime(now.year, now.month - (5 - index), 1));
                final totals = {
                  for (final date in monthStarts) date: 0.0,
                };

                for (final run in runs) {
                  final iso = run['startAt'] as String?;
                  final distance =
                      ((run['distanceKm'] as num?)?.toDouble() ?? 0.0);
                  if (iso == null || distance <= 0) continue;
                  final dt = DateTime.tryParse(iso);
                  if (dt == null) continue;
                  final key = DateTime(dt.year, dt.month, 1);
                  if (totals.containsKey(key)) {
                    totals[key] = totals[key]! + distance;
                  }
                }

                final entries = monthStarts
                    .map((date) => _DistanceEntry(
                          label: _monthLabel(date),
                          distance: (totals[date] ?? 0.0),
                        ))
                    .toList();

                final maxDistance = entries.fold<double>(
                    0, (prev, entry) => math.max(prev, entry.distance));

                if (maxDistance <= 0.01) {
                  return Text('Sin registros recientes',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant));
                }

                return SizedBox(
                  height: 180,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final entry in entries)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('${entry.distance.toStringAsFixed(1)} km',
                                  style: theme.textTheme.labelSmall),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 450),
                                    curve: Curves.easeOut,
                                    width: 24,
                                    height: math.max(
                                      12,
                                      120 *
                                          (entry.distance / maxDistance)
                                              .clamp(0, 1),
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          scheme.primary.withValues(alpha: 0.85),
                                          scheme.secondary.withValues(alpha: 0.65),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(entry.label,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                          color: scheme.onSurfaceVariant)),
                            ],
                          ),
                        )
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator())),
              error: (_, __) => Text('No se pudo cargar',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistanceEntry {
  final String label;
  final double distance;

  const _DistanceEntry({required this.label, required this.distance});
}

class _PaceChips extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> runsAsync;

  const _PaceChips({required this.runsAsync});

  static int? _parsePace(String? pace) {
    if (pace == null || pace.isEmpty) return null;
    final cleaned = pace.replaceAll(RegExp(r'[^0-9:]'), '');
    final parts = cleaned.split(':').where((p) => p.isNotEmpty).toList();
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]);
      final seconds = int.tryParse(parts[1]);
      if (minutes == null || seconds == null) return null;
      return minutes * 60 + seconds;
    }
    if (parts.length == 3) {
      final hours = int.tryParse(parts[0]);
      final minutes = int.tryParse(parts[1]);
      final seconds = int.tryParse(parts[2]);
      if (hours == null || minutes == null || seconds == null) return null;
      return hours * 3600 + minutes * 60 + seconds;
    }
    return null;
  }

  static String _formatPace(int seconds) {
    if (seconds <= 0) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} min/km';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ritmo',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            runsAsync.when(
              data: (runs) {
                final paces = <int>[];
                for (final run in runs) {
                  final paceStr = run['pace'] as String?;
                  final seconds = _parsePace(paceStr);
                  if (seconds != null && seconds > 0) {
                    paces.add(seconds);
                  }
                }

                if (paces.isEmpty) {
                  return Text('Sin datos de ritmo',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant));
                }

                paces.sort();
                final best = paces.first;
                final average =
                    paces.reduce((value, element) => value + element) /
                        paces.length;

                final totalDistance = runs.fold<double>(
                    0.0,
                    (total, run) =>
                        total + ((run['distanceKm'] as num?)?.toDouble() ?? 0.0));

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _PaceInfoChip(
                      icon: Icons.flash_on,
                      label: 'Mejor ritmo',
                      value: _formatPace(best),
                    ),
                    _PaceInfoChip(
                      icon: Icons.equalizer,
                      label: 'Ritmo promedio',
                      value: _formatPace(average.round()),
                    ),
                    _PaceInfoChip(
                      icon: Icons.timeline,
                      label: 'Kilómetros registrados',
                      value: '${totalDistance.toStringAsFixed(1)} km',
                    ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text('No se pudo cargar',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaceInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PaceInfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant
                          .withValues(alpha: 0.8))),
              Text(value,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          )
        ],
      ),
    );
  }
}

class _MapTypeSelector extends StatelessWidget {
  final MapType selected;
  final ValueChanged<MapType> onChanged;

  const _MapTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final options = [
      (MapType.normal, 'Estándar', Icons.map),
      (MapType.satellite, 'Satélite', Icons.satellite_alt_outlined),
      (MapType.terrain, 'Terreno', Icons.terrain),
      (MapType.hybrid, 'Híbrido', Icons.layers_outlined),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final option in options)
          ChoiceChip(
            selected: selected == option.$1,
            onSelected: (_) => onChanged(option.$1),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(option.$3, size: 18),
                const SizedBox(width: 8),
                Text(option.$2),
              ],
            ),
            selectedColor: scheme.primary.withValues(alpha: 0.16),
            backgroundColor: scheme.surface.withValues(alpha: 0.4),
            labelStyle: theme.textTheme.bodyMedium,
            side: BorderSide(
              color: selected == option.$1
                  ? scheme.primary
                  : scheme.outline.withValues(alpha: 0.2),
            ),
          ),
      ],
    );
  }
}

class _ProfileRunTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String distance;
  final String pace;
  final VoidCallback? onTap;

  const _ProfileRunTile({
    required this.title,
    required this.subtitle,
    required this.distance,
    required this.pace,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(title,
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$distance km',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              )),
          Text(pace,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
