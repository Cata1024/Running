import 'package:flutter/material.dart';
import '../design_system/territory_tokens.dart';
import 'aero_surface.dart';

/// ListTile personalizado con acabado Aero glassmorphism
/// 
/// Componente optimizado para listas con mejor accesibilidad y tap targets.
/// 
/// Uso:
/// ```dart
/// AeroListTile(
///   leading: Icon(Icons.person),
///   title: 'Usuario',
///   subtitle: 'user@example.com',
///   trailing: Icon(Icons.chevron_right),
///   onTap: () => navigate(),
/// )
/// ```
class AeroListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final bool selected;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AeroLevel level;
  final String? semanticLabel;
  final bool showDivider;
  final Color? backgroundColor;

  const AeroListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.selected = false,
    this.padding,
    this.margin,
    this.level = AeroLevel.subtle,
    this.semanticLabel,
    this.showDivider = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final effectivePadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: TerritoryTokens.space16,
          vertical: TerritoryTokens.space12,
        );

    // Garantizar tap target mínimo de 48px (WCAG)
    final minHeight = TerritoryTokens.tapTarget.recommended;

    Widget content = Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: effectivePadding,
      child: Row(
        children: [
          // Leading
          if (leading != null) ...[
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: TerritoryTokens.tapTarget.minimum,
                minHeight: TerritoryTokens.tapTarget.minimum,
              ),
              child: Center(child: leading),
            ),
            const SizedBox(width: TerritoryTokens.space12),
          ],

          // Title y Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (title != null)
                  DefaultTextStyle.merge(
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: enabled
                          ? (selected ? scheme.primary : scheme.onSurface)
                          : scheme.onSurface.withValues(alpha: 0.38),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    child: title!,
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: TerritoryTokens.space4),
                  DefaultTextStyle.merge(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: enabled
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface.withValues(alpha: 0.38),
                    ),
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),

          // Trailing
          if (trailing != null) ...[
            const SizedBox(width: TerritoryTokens.space12),
            trailing!,
          ],
        ],
      ),
    );

    // Wrap con Aero styling si no está deshabilitado
    if (level != AeroLevel.ghost || selected) {
      content = AeroSurface(
        level: level,
        padding: EdgeInsets.zero,
        margin: margin,
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.12)
                : backgroundColor,
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
          ),
          child: content,
        ),
      );
    }

    // Agregar interactividad
    if (onTap != null || onLongPress != null) {
      content = Semantics(
        button: true,
        enabled: enabled,
        selected: selected,
        label: semanticLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            onLongPress: enabled ? onLongPress : null,
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
            child: content,
          ),
        ),
      );
    }

    // Wrap final con divider si es necesario
    if (showDivider) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          content,
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ],
      );
    }

    return content;
  }
}

/// Variante compacta de AeroListTile
class AeroListTileCompact extends StatelessWidget {
  final Widget? leading;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;

  const AeroListTileCompact({
    super.key,
    this.leading,
    required this.title,
    this.trailing,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AeroListTile(
      leading: leading,
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
      selected: selected,
      padding: const EdgeInsets.symmetric(
        horizontal: TerritoryTokens.space12,
        vertical: TerritoryTokens.space8,
      ),
      level: AeroLevel.ghost,
    );
  }
}

/// AeroListTile con switch
class AeroSwitchListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const AeroSwitchListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AeroListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeThumbColor: scheme.primary,
      ),
      onTap: enabled
          ? () => onChanged?.call(!value)
          : null,
      enabled: enabled,
      semanticLabel: '$title: ${value ? "Activado" : "Desactivado"}',
    );
  }
}

/// AeroListTile con checkbox
class AeroCheckboxListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const AeroCheckboxListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AeroListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Checkbox(
        value: value,
        onChanged: enabled ? (val) => onChanged?.call(val ?? false) : null,
        activeColor: scheme.primary,
      ),
      onTap: enabled
          ? () => onChanged?.call(!value)
          : null,
      enabled: enabled,
      selected: value,
      semanticLabel: '$title: ${value ? "Seleccionado" : "No seleccionado"}',
    );
  }
}
