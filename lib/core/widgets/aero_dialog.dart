import 'package:flutter/material.dart';
import '../design_system/territory_tokens.dart';
import 'aero_surface.dart';
import 'aero_button.dart';

/// Dialog personalizado con acabado Aero glassmorphism
/// 
/// Uso:
/// ```dart
/// AeroDialog.show(
///   context,
///   title: 'Confirmar',
///   message: '¿Estás seguro de continuar?',
///   confirmText: 'Sí',
///   cancelText: 'No',
///   onConfirm: () => print('Confirmado'),
/// )
/// ```
class AeroDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? content;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDismissible;
  final IconData? icon;
  final Color? iconColor;
  final bool isDestructive;

  const AeroDialog({
    super.key,
    this.title,
    this.message,
    this.content,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.isDismissible = true,
    this.icon,
    this.iconColor,
    this.isDestructive = false,
  });

  /// Muestra el dialog y retorna true si se confirmó
  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? message,
    Widget? content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDismissible = true,
    IconData? icon,
    Color? iconColor,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => AeroDialog(
        title: title,
        message: message,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDismissible: isDismissible,
        icon: icon,
        iconColor: iconColor,
        isDestructive: isDestructive,
      ),
    );
  }

  /// Dialog de confirmación simple
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool isDestructive = false,
  }) {
    return show(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: isDestructive ? Icons.warning_amber_rounded : Icons.help_outline,
      iconColor: isDestructive
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.primary,
      isDestructive: isDestructive,
    );
  }

  /// Dialog de información
  static Future<bool?> info(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Entendido',
  }) {
    return show(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      icon: Icons.info_outline,
      iconColor: Theme.of(context).colorScheme.primary,
    );
  }

  /// Dialog de error
  static Future<bool?> error(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Cerrar',
  }) {
    return show(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      icon: Icons.error_outline,
      iconColor: Theme.of(context).colorScheme.error,
      isDestructive: true,
    );
  }

  void _handleConfirm(BuildContext context) {
    onConfirm?.call();
    Navigator.of(context).pop(true);
  }

  void _handleCancel(BuildContext context) {
    onCancel?.call();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AeroSurface(
        level: AeroLevel.strong,
        padding: const EdgeInsets.all(TerritoryTokens.space24),
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono (opcional)
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(TerritoryTokens.space16),
                decoration: BoxDecoration(
                  color: (iconColor ?? scheme.primary).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: iconColor ?? scheme.primary,
                ),
              ),
              const SizedBox(height: TerritoryTokens.space16),
            ],

            // Título
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TerritoryTokens.space12),
            ],

            // Mensaje o contenido personalizado
            if (message != null)
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              )
            else if (content != null)
              content!,

            const SizedBox(height: TerritoryTokens.space24),

            // Botones
            Row(
              children: [
                // Botón cancelar
                if (cancelText != null) ...[
                  Expanded(
                    child: AeroButton(
                      onPressed: () => _handleCancel(context),
                      isOutlined: true,
                      semanticLabel: cancelText,
                      child: Text(cancelText!),
                    ),
                  ),
                  const SizedBox(width: TerritoryTokens.space12),
                ],

                // Botón confirmar
                if (confirmText != null)
                  Expanded(
                    child: AeroButton(
                      onPressed: () => _handleConfirm(context),
                      backgroundColor: isDestructive ? scheme.error : null,
                      semanticLabel: confirmText,
                      child: Text(confirmText!),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading dialog con glassmorphism
class AeroLoadingDialog extends StatelessWidget {
  final String? message;

  const AeroLoadingDialog({
    super.key,
    this.message,
  });

  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AeroLoadingDialog(message: message),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AeroSurface(
        level: AeroLevel.strong,
        padding: const EdgeInsets.all(TerritoryTokens.space32),
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: TerritoryTokens.space16),
              Text(
                message!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
