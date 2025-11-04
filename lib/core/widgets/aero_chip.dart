import 'package:flutter/material.dart';
import '../design_system/territory_tokens.dart';
import 'aero_surface.dart';

/// Chip personalizado con acabado Aero glassmorphism
/// 
/// Uso:
/// ```dart
/// AeroChip(
///   label: 'Running',
///   icon: Icons.directions_run,
///   onTap: () => filter('running'),
/// )
/// ```
class AeroChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Widget? avatar;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool selected;
  final bool enabled;
  final Color? backgroundColor;
  final Color? selectedColor;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;

  const AeroChip({
    super.key,
    required this.label,
    this.icon,
    this.avatar,
    this.onTap,
    this.onDelete,
    this.selected = false,
    this.enabled = true,
    this.backgroundColor,
    this.selectedColor,
    this.padding,
    this.semanticLabel,
  });

  @override
  State<AeroChip> createState() => _AeroChipState();
}

class _AeroChipState extends State<AeroChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AeroChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final effectivePadding = widget.padding ??
        EdgeInsets.symmetric(
          horizontal: widget.icon != null || widget.avatar != null
              ? TerritoryTokens.space12
              : TerritoryTokens.space16,
          vertical: TerritoryTokens.space8,
        );

    final effectiveBackgroundColor = widget.selected
        ? (widget.selectedColor ?? scheme.primaryContainer)
        : widget.backgroundColor;

    final textColor = widget.selected
        ? scheme.onPrimaryContainer
        : scheme.onSurface;

    Widget content = Container(
      constraints: BoxConstraints(
        minHeight: TerritoryTokens.tapTarget.minimum,
      ),
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor?.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusPill),
        border: Border.all(
          color: widget.selected
              ? scheme.primary.withValues(alpha: 0.3)
              : scheme.outline.withValues(alpha: 0.2),
          width: widget.selected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar o icono
          if (widget.avatar != null) ...[
            SizedBox(
              width: 24,
              height: 24,
              child: widget.avatar,
            ),
            const SizedBox(width: TerritoryTokens.space8),
          ] else if (widget.icon != null) ...[
            Icon(
              widget.icon,
              size: 18,
              color: textColor,
            ),
            const SizedBox(width: TerritoryTokens.space8),
          ],

          // Label
          Text(
            widget.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: widget.enabled ? textColor : textColor.withValues(alpha: 0.38),
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),

          // Delete button
          if (widget.onDelete != null) ...[
            const SizedBox(width: TerritoryTokens.space8),
            GestureDetector(
              onTap: widget.enabled ? widget.onDelete : null,
              child: Icon(
                Icons.close,
                size: 18,
                color: textColor,
              ),
            ),
          ],
        ],
      ),
    );

    // Wrap con AeroSurface para glassmorphism
    content = AeroSurface(
      level: widget.selected ? AeroLevel.medium : AeroLevel.subtle,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(TerritoryTokens.radiusPill),
      child: content,
    );

    // Agregar interactividad
    if (widget.onTap != null) {
      content = Semantics(
        button: true,
        selected: widget.selected,
        enabled: widget.enabled,
        label: widget.semanticLabel ?? widget.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? widget.onTap : null,
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusPill),
            child: content,
          ),
        ),
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Opacity(
        opacity: widget.enabled ? 1.0 : 0.6,
        child: content,
      ),
    );
  }
}

/// Chip de filtro con estado seleccionado
class AeroFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const AeroFilterChip({
    super.key,
    required this.label,
    this.icon,
    required this.selected,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AeroChip(
      label: label,
      icon: icon,
      selected: selected,
      onTap: onSelected != null ? () => onSelected!(!selected) : null,
      semanticLabel: '$label filter ${selected ? "activo" : "inactivo"}',
    );
  }
}

/// Chip de acción simple
class AeroActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const AeroActionChip({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AeroChip(
      label: label,
      icon: icon,
      onTap: onPressed,
      semanticLabel: label,
    );
  }
}

/// Chip de entrada con delete
class AeroInputChip extends StatelessWidget {
  final String label;
  final Widget? avatar;
  final VoidCallback? onDeleted;

  const AeroInputChip({
    super.key,
    required this.label,
    this.avatar,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return AeroChip(
      label: label,
      avatar: avatar,
      onDelete: onDeleted,
      semanticLabel: label,
    );
  }
}
