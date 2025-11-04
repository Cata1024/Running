import 'dart:ui';

import 'package:flutter/material.dart';

import '../design_system/territory_tokens.dart';
import 'aero_surface.dart';

class AeroNavBarItem {
  final IconData icon;
  final String label;

  const AeroNavBarItem({required this.icon, required this.label});
}

class AeroNavBar extends StatefulWidget {
  final List<AeroNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final bool visible;

  static const double preferredHeight = 64 + TerritoryTokens.space24;

  const AeroNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onItemSelected,
    this.visible = true,
  }) : assert(items.length >= 2, 'Se requieren al menos dos items en la barra');

  @override
  State<AeroNavBar> createState() => _AeroNavBarState();
}

class _AeroNavBarState extends State<AeroNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: TerritoryTokens.durationNormal,
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _offset = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    if (widget.visible) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant AeroNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.items;
    final currentIndex = widget.currentIndex.clamp(0, items.length - 1);

    return SizedBox.expand(
      child: IgnorePointer(
        ignoring: !_controller.isAnimating && _controller.value == 0,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: _offset,
                child: FadeTransition(
                  opacity: _opacity,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TerritoryTokens.space16,
                      0,
                      TerritoryTokens.space16,
                      TerritoryTokens.space24,
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: _AeroNavShell(
            items: items,
            currentIndex: currentIndex,
            onItemSelected: widget.onItemSelected,
            theme: theme,
          ),
        ),
      ),
    );
  }
}

class _AeroNavShell extends StatelessWidget {
  final List<AeroNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final ThemeData theme;

  const _AeroNavShell({
    required this.items,
    required this.currentIndex,
    required this.onItemSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;

    return SizedBox(
      height: 64,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusXLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: TerritoryTokens.blurMedium,
            sigmaY: TerritoryTokens.blurMedium,
          ),
          child: AeroSurface(
            level: AeroLevel.medium,
            borderRadius:
                BorderRadius.circular(TerritoryTokens.radiusXLarge),
            enableBlur: false,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final selected = index == currentIndex;
                final color = selected
                    ? scheme.primary
                    : scheme.onSurfaceVariant.withValues(alpha: 0.6);

                return Expanded(
                  child: _NavButton(
                    icon: item.icon,
                    label: item.label,
                    color: color,
                    selected: selected,
                    onTap: () => onItemSelected(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: label,
      selected: selected,
      enabled: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
        duration: TerritoryTokens.durationFast,
        padding: const EdgeInsets.symmetric(
          vertical: TerritoryTokens.space8,
          horizontal: TerritoryTokens.space12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: TerritoryTokens.space4),
            AnimatedDefaultTextStyle(
              duration: TerritoryTokens.durationFast,
              style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ) ??
                  TextStyle(color: color),
              child: Text(label),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
