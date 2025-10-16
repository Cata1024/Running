import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/glass_button.dart';
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'photoURL': url}, SetOptions(merge: true));
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
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? const Icon(Icons.person, size: 14)
                            : null),
                    const SizedBox(width: 8),
                    Text(user?.displayName ?? 'Usuario',
                        style: theme.textTheme.titleSmall),
                  ]),
                ),
                background: Stack(children: [
                  // background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        colorA.withOpacity(0.18),
                        colorB.withOpacity(0.12)
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
                                        colorB.withOpacity(0.06),
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
                            user: user,
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
                                  Text(user?.displayName ?? 'Usuario',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800)),
                                  if (user?.email != null)
                                    Text(user!.email!,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                                color: onSurfaceVariant)),
                                  const SizedBox(height: 8),
                                  profileDocAsync.when(
                                    data: (data) {
                                      final iso =
                                          data?['lastActivityAt'] as String?;
                                      if (iso == null)
                                        return const SizedBox.shrink();
                                      final dt = DateTime.tryParse(iso);
                                      if (dt == null)
                                        return const SizedBox.shrink();
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
                                      Row(children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: LinearProgressIndicator(
                                                value: percent,
                                                minHeight: 10,
                                                backgroundColor: theme
                                                    .colorScheme.surfaceVariant
                                                    .withOpacity(0.6)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                            '${(percent * 100).toStringAsFixed(0)}%',
                                            style: theme.textTheme.bodySmall),
                                      ])
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
                                String fmt(int s) {
                                  final h =
                                      (s ~/ 3600).toString().padLeft(2, '0');
                                  final m = ((s % 3600) ~/ 60)
                                      .toString()
                                      .padLeft(2, '0');
                                  return '$h:$m';
                                }

                                final t = territoryDocAsync.value;
                                final areaHa =
                                    (((t?['totalAreaM2'] as num?)?.toDouble() ??
                                                0.0) /
                                            10000.0)
                                        .toStringAsFixed(2);

                                return GridView.count(
                                  shrinkWrap: true,
                                  crossAxisCount:
                                      MediaQuery.of(context).size.width > 700
                                          ? 4
                                          : 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    _StatCard(
                                        icon: Icons.directions_run,
                                        label: 'Carreras',
                                        value: '$runs',
                                        smallChart: _MiniSparkline(
                                            values: [1, 2, 3, 2, 4, 3])),
                                    _StatCard(
                                        icon: Icons.route,
                                        label: 'Distancia',
                                        value:
                                            '${distKm.toStringAsFixed(1)} km',
                                        smallChart: _MiniSparkline(
                                            values: [0.5, 1.2, 2.0, 1.8, 2.2])),
                                    _StatCard(
                                        icon: Icons.timer,
                                        label: 'Tiempo',
                                        value: fmt(totalSec),
                                        smallChart: _MiniSparkline(
                                            values: [30, 40, 50, 35, 60])),
                                    _StatCard(
                                        icon: Icons.terrain,
                                        label: 'Territorio',
                                        value: '$areaHa ha',
                                        smallChart: _MiniSparkline(
                                            values: [0.2, 0.3, 0.5, 0.4])),
                                  ],
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

                    // Achievements as fancy medals with entrance animation
                    GlassContainer(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text('Logros',
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              TextButton(
                                  onPressed: () {},
                                  child: const Text('Ver todos')),
                            ]),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 150,
                              child: profileDocAsync.when(
                                data: (p) {
                                  final totalRuns =
                                      (p?['totalRuns'] as num?)?.toInt() ?? 0;
                                  final totalKm = ((p?['totalDistance'] as num?)
                                          ?.toDouble() ??
                                      0.0);
                                  final achievements = [
                                    _Medal(
                                        icon: Icons.whatshot,
                                        label: 'Primera carrera',
                                        done: totalRuns >= 1,
                                        color: colorA),
                                    _Medal(
                                        icon: Icons.emoji_events,
                                        label: '10K completado',
                                        done: totalKm >= 10,
                                        color: colorB),
                                    _Medal(
                                        icon: Icons.fitness_center,
                                        label: '100km total',
                                        done: totalKm >= 100,
                                        color: theme.colorScheme.tertiary),
                                    _Medal(
                                        icon: Icons.schedule,
                                        label: '7 días activo',
                                        done: (p?['streak7'] ?? false) == true,
                                        color:
                                            theme.colorScheme.primaryContainer),
                                  ];

                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: 600),
                                    builder: (context, v, child) {
                                      return Transform.translate(
                                          offset: Offset(0, (1 - v) * 8),
                                          child: Opacity(
                                              opacity: v, child: child));
                                    },
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemBuilder: (_, i) => achievements[i],
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 12),
                                      itemCount: achievements.length,
                                    ),
                                  );
                                },
                                loading: () => const Center(
                                    child: CircularProgressIndicator()),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            ),
                          ]),
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
                        backgroundColor: Colors.red.withOpacity(0.10),
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
                color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
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

class _ProfileAvatar extends StatelessWidget {
  final User? user;
  final bool uploading;
  final VoidCallback onTap;
  final AnimationController pulse;
  final Gradient outerGradient;
  const _ProfileAvatar(
      {required this.user,
      required this.uploading,
      required this.onTap,
      required this.pulse,
      required this.outerGradient});

  @override
  Widget build(BuildContext context) {
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
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8))
                  ]),
              child: ClipOval(
                child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                        width: 106,
                        height: 106,
                        color: Colors.white.withOpacity(0.06),
                        child: _avatarImage())),
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
                                .withOpacity(0.28),
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

  Widget _avatarImage() {
    if (user?.photoURL != null)
      return Image.network(user!.photoURL!,
          width: 106, height: 106, fit: BoxFit.cover);
    return SizedBox(
        width: 106,
        height: 106,
        child: Center(
            child: Icon(Icons.person,
                size: 52, color: Colors.white.withOpacity(0.95))));
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
      ..color = Colors.white.withOpacity(0.06)
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
            color: theme.colorScheme.surface.withOpacity(0.06)),
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
                          widget.color.withOpacity(0.9),
                          widget.color.withOpacity(0.6)
                        ])))),
            CircleAvatar(
                radius: 30,
                backgroundColor:
                    widget.done ? widget.color : widget.color.withOpacity(0.14),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget smallChart;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.smallChart});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
                radius: 16,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.12),
                child: Icon(icon,
                    size: 16, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 8),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant))
          ]),
          const SizedBox(height: 12),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const Spacer(),
          SizedBox(height: 36, child: smallChart)
        ]),
      ),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  final List<double> values;
  const _MiniSparkline({required this.values});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        painter: _SparkPainter(
            values: values, color: Theme.of(context).colorScheme.primary),
        size: const Size(double.infinity, 36));
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _SparkPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final paint = Paint()
      ..color = color.withOpacity(0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height -
          ((values[i] - min) / ((max - min).abs() < 0.0001 ? 1 : (max - min))) *
              size.height;
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    // small dot at end
    final endX = size.width;
    final endY = size.height -
        ((values.last - min) / ((max - min).abs() < 0.0001 ? 1 : (max - min))) *
            size.height;
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(endX, endY), 2.8, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
