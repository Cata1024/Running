import 'package:flutter/material.dart';
import '../design_system/territory_tokens.dart';

/// Badge personalizado con acabado Aero
/// 
/// Uso:
/// ```dart
/// AeroBadge(
///   count: 5,
///   child: Icon(Icons.notifications),
/// )
/// ```
class AeroBadge extends StatelessWidget {
  final Widget child;
  final int? count;
  final String? label;
  final Color? backgroundColor;
  final Color? textColor;
  final bool show;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry? padding;

  const AeroBadge({
    super.key,
    required this.child,
    this.count,
    this.label,
    this.backgroundColor,
    this.textColor,
    this.show = true,
    this.alignment = Alignment.topRight,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (!show || (count == null && label == null)) {
      return child;
    }

    final displayText = label ?? (count != null && count! > 99 ? '99+' : count.toString());
    final effectiveBackgroundColor = backgroundColor ?? scheme.error;
    final effectiveTextColor = textColor ?? scheme.onError;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: Align(
            alignment: alignment,
            child: Transform.translate(
              offset: const Offset(8, -8),
              child: Container(
                padding: padding ??
                    EdgeInsets.symmetric(
                      horizontal: count != null && count! > 9
                          ? TerritoryTokens.space8
                          : 6.0,
                      vertical: TerritoryTokens.space4,
                    ),
                constraints: BoxConstraints(
                  minWidth: count != null && count! > 9 ? 24 : 20,
                  minHeight: 20,
                ),
                decoration: BoxDecoration(
                  color: effectiveBackgroundColor,
                  borderRadius: BorderRadius.circular(TerritoryTokens.radiusPill),
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveBackgroundColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    displayText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: effectiveTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Badge simple con punto
class AeroDotBadge extends StatelessWidget {
  final Widget child;
  final bool show;
  final Color? color;
  final double size;
  final AlignmentGeometry alignment;

  const AeroDotBadge({
    super.key,
    required this.child,
    this.show = true,
    this.color,
    this.size = 10,
    this.alignment = Alignment.topRight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (!show) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: Align(
            alignment: alignment,
            child: Transform.translate(
              offset: const Offset(4, -4),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color ?? scheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (color ?? scheme.error).withValues(alpha: 0.4),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Badge de status (online/offline/away)
class AeroStatusBadge extends StatelessWidget {
  final Widget child;
  final AeroStatus status;
  final double size;

  const AeroStatusBadge({
    super.key,
    required this.child,
    required this.status,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor;
    switch (status) {
      case AeroStatus.online:
        statusColor = Colors.green;
        break;
      case AeroStatus.offline:
        statusColor = Colors.grey;
        break;
      case AeroStatus.away:
        statusColor = Colors.orange;
        break;
      case AeroStatus.busy:
        statusColor = Colors.red;
        break;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.surface,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum AeroStatus {
  online,
  offline,
  away,
  busy,
}
