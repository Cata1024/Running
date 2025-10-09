import 'dart:ui';

import 'package:flutter/material.dart';

/// Semitransparent glass panel used to achieve the NeoGlass look & feel.
///
/// It applies a blur behind the content, a subtle gradient overlay and a thin
/// border highlight to help the panel float above the background while keeping
/// legibility for the Data Clean layout.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final Color? overlayColor;
  final double blurSigma;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.overlayColor,
    this.blurSigma = 18,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (overlayColor ?? colorScheme.surface.withOpacity(0.24)),
                (overlayColor ?? colorScheme.surface.withOpacity(0.08)),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: colorScheme.onSurface.withOpacity(0.08),
              width: 1.2,
            ),
            borderRadius: borderRadius.resolve(TextDirection.ltr),
            boxShadow: [
              BoxShadow(
                color: colorScheme.surfaceTint.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            padding: padding,
            color: Colors.transparent,
            child: child,
          ),
        ),
      ),
    );
  }
}
