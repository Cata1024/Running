import 'package:flutter/material.dart';
import 'territory_tokens.dart';

/// Utilidades para manejar focus indicators accesibles
/// 
/// Provee decoraciones y widgets para mostrar el estado de foco
/// de manera clara y accesible (WCAG 2.1 Success Criterion 2.4.7)
class FocusUtils {
  FocusUtils._();

  // ============================================================================
  // FOCUS DECORATIONS
  // ============================================================================

  /// Obtiene un BoxDecoration para indicador de foco
  static BoxDecoration getFocusDecoration({
    required BuildContext context,
    BorderRadius? borderRadius,
    double borderWidth = 2.0,
  }) {
    final scheme = Theme.of(context).colorScheme;
    
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(TerritoryTokens.radiusMedium),
      border: Border.all(
        color: scheme.primary,
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: scheme.primary.withValues(alpha: 0.3),
          blurRadius: 4,
          spreadRadius: 1,
        ),
      ],
    );
  }

  /// Obtiene el color del indicador de foco
  static Color getFocusColor(BuildContext context, {double opacity = 0.3}) {
    return Theme.of(context).colorScheme.primary.withValues(alpha: opacity);
  }

  // ============================================================================
  // FOCUS RING PAINTER
  // ============================================================================

  /// Pinta un anillo de foco alrededor del widget
  static CustomPainter getFocusRingPainter({
    required Color color,
    double strokeWidth = 2.0,
    double? borderRadius,
  }) {
    return _FocusRingPainter(
      color: color,
      strokeWidth: strokeWidth,
      borderRadius: borderRadius,
    );
  }
}

/// Painter para dibujar un anillo de foco
class _FocusRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double? borderRadius;

  _FocusRingPainter({
    required this.color,
    required this.strokeWidth,
    this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    if (borderRadius != null && borderRadius! > 0) {
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(borderRadius!),
      );
      canvas.drawRRect(rrect, paint);
    } else {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_FocusRingPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}

/// Widget que envuelve otro widget con un indicador de foco
class FocusIndicator extends StatefulWidget {
  final Widget child;
  final FocusNode? focusNode;
  final BorderRadius? borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry? margin;
  final bool showFocusRing;

  const FocusIndicator({
    super.key,
    required this.child,
    this.focusNode,
    this.borderRadius,
    this.borderWidth = 2.0,
    this.margin,
    this.showFocusRing = true,
  });

  @override
  State<FocusIndicator> createState() => _FocusIndicatorState();
}

class _FocusIndicatorState extends State<FocusIndicator> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(FocusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showFocusRing || !_isFocused) {
      return widget.child;
    }

    return Container(
      margin: widget.margin,
      decoration: FocusUtils.getFocusDecoration(
        context: context,
        borderRadius: widget.borderRadius,
        borderWidth: widget.borderWidth,
      ),
      child: widget.child,
    );
  }
}

/// Mixin para agregar focus indicators a widgets personalizados
mixin FocusIndicatorMixin<T extends StatefulWidget> on State<T> {
  late FocusNode focusNode;
  bool get isFocused => focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    focusNode.removeListener(_handleFocusChange);
    focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {});
  }

  /// Obtiene la decoración de foco si el widget está enfocado
  BoxDecoration? getFocusDecoration(BuildContext context, {BorderRadius? borderRadius}) {
    if (!isFocused) return null;
    return FocusUtils.getFocusDecoration(
      context: context,
      borderRadius: borderRadius,
    );
  }

  /// Obtiene el color de foco si el widget está enfocado
  Color? getFocusColor(BuildContext context) {
    if (!isFocused) return null;
    return FocusUtils.getFocusColor(context);
  }
}
