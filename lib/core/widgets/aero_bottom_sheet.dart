import 'package:flutter/material.dart';
import '../design_system/territory_tokens.dart';
import 'aero_surface.dart';

/// Bottom sheet personalizado con acabado Aero glassmorphism
/// 
/// Uso:
/// ```dart
/// AeroBottomSheet.show(
///   context,
///   title: 'Opciones',
///   child: Column(
///     children: [
///       ListTile(title: Text('Opción 1')),
///       ListTile(title: Text('Opción 2')),
///     ],
///   ),
/// )
/// ```
class AeroBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final bool showDragHandle;
  final double? maxHeight;
  final EdgeInsetsGeometry? padding;

  const AeroBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.showDragHandle = true,
    this.maxHeight,
    this.padding,
  });

  /// Muestra el bottom sheet
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required Widget child,
    bool showDragHandle = true,
    double? maxHeight,
    EdgeInsetsGeometry? padding,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      builder: (context) => AeroBottomSheet(
        title: title,
        maxHeight: maxHeight,
        padding: padding,
        showDragHandle: showDragHandle,
        child: child,
      ),
    );
  }

  /// Bottom sheet con lista de opciones
  static Future<T?> showList<T>(
    BuildContext context, {
    required String title,
    required List<AeroBottomSheetItem<T>> items,
  }) {
    return show<T>(
      context,
      title: title,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return _AeroBottomSheetListItem<T>(item: item);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final defaultMaxHeight = mediaQuery.size.height * 0.9;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? defaultMaxHeight,
      ),
      child: AeroSurface(
        level: AeroLevel.strong,
        padding: EdgeInsets.zero,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(TerritoryTokens.radiusXLarge),
          topRight: Radius.circular(TerritoryTokens.radiusXLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            if (showDragHandle) ...[
              const SizedBox(height: TerritoryTokens.space12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(TerritoryTokens.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: TerritoryTokens.space12),
            ] else
              const SizedBox(height: TerritoryTokens.space24),

            // Título
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TerritoryTokens.space24,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title!,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: TerritoryTokens.space16),
            ],

            // Contenido
            Flexible(
              child: Padding(
                padding: padding ??
                    const EdgeInsets.only(
                      left: TerritoryTokens.space24,
                      right: TerritoryTokens.space24,
                      bottom: TerritoryTokens.space24,
                    ),
                child: child,
              ),
            ),

            // Safe area para el notch inferior
            SizedBox(height: mediaQuery.padding.bottom),
          ],
        ),
      ),
    );
  }
}

/// Item para listas en bottom sheets
class AeroBottomSheetItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool isDestructive;
  final bool isSelected;

  const AeroBottomSheetItem({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
    this.isDestructive = false,
    this.isSelected = false,
  });
}

class _AeroBottomSheetListItem<T> extends StatelessWidget {
  final AeroBottomSheetItem<T> item;

  const _AeroBottomSheetListItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    
    final color = item.isDestructive
        ? scheme.error
        : (item.iconColor ?? scheme.onSurface);

    return Semantics(
      button: true,
      selected: item.isSelected,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(item.value),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TerritoryTokens.space24,
            vertical: TerritoryTokens.space16,
          ),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: TerritoryTokens.space16),
              ],
              Expanded(
                child: Text(
                  item.label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: item.isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ),
              if (item.isSelected)
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
  }
}

/// Bottom sheet con formulario
class AeroFormBottomSheet extends StatelessWidget {
  final String title;
  final Widget form;
  final VoidCallback? onSubmit;
  final String submitText;
  final bool isSubmitting;

  const AeroFormBottomSheet({
    super.key,
    required this.title,
    required this.form,
    this.onSubmit,
    this.submitText = 'Guardar',
    this.isSubmitting = false,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget form,
    VoidCallback? onSubmit,
    String submitText = 'Guardar',
  }) {
    return AeroBottomSheet.show<T>(
      context,
      title: title,
      child: form,
      showDragHandle: true,
      maxHeight: MediaQuery.of(context).size.height * 0.9,
    );
  }

  @override
  Widget build(BuildContext context) {
    return form;
  }
}
