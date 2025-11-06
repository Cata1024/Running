import 'package:flutter/material.dart';
import '../design_system/territory_tokens.dart';
import 'aero_surface.dart';

/// Dropdown personalizado con acabado Aero glassmorphism
/// 
/// Uso:
/// ```dart
/// AeroDropdown<String>(
///   value: selectedValue,
///   items: ['Opción 1', 'Opción 2', 'Opción 3'],
///   onChanged: (value) => setState(() => selectedValue = value),
///   hint: 'Selecciona una opción',
/// )
/// ```
class AeroDropdown<T> extends StatefulWidget {
  final T? value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String Function(T)? itemLabel;
  final Widget Function(T)? itemBuilder;
  final bool enabled;
  final String? semanticLabel;
  final EdgeInsetsGeometry? padding;
  final double? width;

  const AeroDropdown({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.itemLabel,
    this.itemBuilder,
    this.enabled = true,
    this.semanticLabel,
    this.padding,
    this.width,
  });

  @override
  State<AeroDropdown<T>> createState() => _AeroDropdownState<T>();
}

class _AeroDropdownState<T> extends State<AeroDropdown<T>> {
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _key = GlobalKey();

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (!widget.enabled || widget.items.isEmpty) return;

    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _DropdownOverlay<T>(
        layerLink: _layerLink,
        width: size.width,
        items: widget.items,
        selectedValue: widget.value,
        itemLabel: widget.itemLabel,
        itemBuilder: widget.itemBuilder,
        onItemSelected: (value) {
          widget.onChanged?.call(value);
          _closeDropdown();
        },
        onDismiss: _closeDropdown,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  String _getDisplayText() {
    if (widget.value != null) {
      return widget.itemLabel?.call(widget.value as T) ?? 
             widget.value.toString();
    }
    return widget.hint ?? 'Seleccionar';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final disabled = !widget.enabled || widget.onChanged == null;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.semanticLabel ?? widget.hint,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          key: _key,
          onTap: disabled ? null : _toggleDropdown,
          child: Opacity(
            opacity: disabled ? 0.6 : 1.0,
            child: AeroSurface(
              level: AeroLevel.medium,
              width: widget.width,
              padding: widget.padding ??
                  const EdgeInsets.symmetric(
                    horizontal: TerritoryTokens.space16,
                    vertical: TerritoryTokens.space12,
                  ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _getDisplayText(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: widget.value == null
                            ? scheme.onSurface.withValues(alpha: 0.5)
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: TerritoryTokens.space8),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0.0,
                    duration: TerritoryTokens.durationFast,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay que muestra las opciones del dropdown
class _DropdownOverlay<T> extends StatelessWidget {
  final LayerLink layerLink;
  final double width;
  final List<T> items;
  final T? selectedValue;
  final String Function(T)? itemLabel;
  final Widget Function(T)? itemBuilder;
  final ValueChanged<T> onItemSelected;
  final VoidCallback onDismiss;

  const _DropdownOverlay({
    required this.layerLink,
    required this.width,
    required this.items,
    this.selectedValue,
    this.itemLabel,
    this.itemBuilder,
    required this.onItemSelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      child: Stack(
        children: [
          CompositedTransformFollower(
            link: layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56), // Altura del dropdown trigger
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: width,
                constraints: const BoxConstraints(maxHeight: 300),
                child: AeroSurface(
                  level: AeroLevel.strong,
                  padding: const EdgeInsets.symmetric(
                    vertical: TerritoryTokens.space8,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = item == selectedValue;

                      return Semantics(
                        button: true,
                        selected: isSelected,
                        child: InkWell(
                          onTap: () => onItemSelected(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: TerritoryTokens.space16,
                              vertical: TerritoryTokens.space12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? scheme.primary.withValues(alpha: 0.12)
                                  : Colors.transparent,
                            ),
                            child: itemBuilder?.call(item) ??
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        itemLabel?.call(item) ?? item.toString(),
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: isSelected
                                              ? scheme.primary
                                              : scheme.onSurface,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check,
                                        color: scheme.primary,
                                        size: 20,
                                      ),
                                  ],
                                ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
