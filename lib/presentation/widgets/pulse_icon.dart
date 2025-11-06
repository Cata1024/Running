import 'package:flutter/material.dart';

/// Ícono con animación de pulso
class PulseIcon extends StatefulWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final Duration duration;

  const PulseIcon({
    super.key,
    required this.icon,
    this.color,
    this.size = 24,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<PulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: false);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse effect
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Icon(
                  widget.icon,
                  size: widget.size,
                  color: widget.color,
                ),
              ),
            );
          },
        ),
        // Main icon
        Icon(
          widget.icon,
          size: widget.size,
          color: widget.color,
        ),
      ],
    );
  }
}
