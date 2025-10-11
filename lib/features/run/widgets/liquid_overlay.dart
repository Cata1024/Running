import 'package:flutter/material.dart';

import 'glass_panel.dart';

class LiquidOverlay extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final Color? overlayColor;
  final double blurSigma;

  const LiquidOverlay({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.overlayColor,
    this.blurSigma = 18,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: padding,
      borderRadius: borderRadius,
      overlayColor: overlayColor,
      blurSigma: blurSigma,
      child: child,
    );
  }
}
