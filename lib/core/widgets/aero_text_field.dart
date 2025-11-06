import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/territory_tokens.dart';
import 'aero_surface.dart';

/// TextField personalizado con estilo Aero y glassmorphism
/// 
/// Incluye validación en tiempo real, estados de error mejorados
/// y accesibilidad incorporada.
class AeroTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool showCounter;
  final bool autovalidate;
  final AutovalidateMode? autovalidateMode;
  final EdgeInsets? contentPadding;
  final AeroLevel level;
  final String? semanticLabel;

  const AeroTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.validator,
    this.showCounter = false,
    this.autovalidate = false,
    this.autovalidateMode,
    this.contentPadding,
    this.level = AeroLevel.subtle,
    this.semanticLabel,
  });

  @override
  State<AeroTextField> createState() => _AeroTextFieldState();
}

class _AeroTextFieldState extends State<AeroTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;
  bool _isFocused = false;
  String? _validationError;
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    
    _animationController = AnimationController(
      duration: TerritoryTokens.durationFast,
      vsync: this,
    );
    
    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.controller != null) {
      _currentLength = widget.controller!.text.length;
      widget.controller!.addListener(_handleTextChange);
    }
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (_isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _validateField();
      }
    });
  }

  void _handleTextChange() {
    setState(() {
      _currentLength = widget.controller?.text.length ?? 0;
      if (widget.autovalidate) {
        _validateField();
      }
    });
  }

  void _validateField() {
    if (widget.validator != null) {
      final error = widget.validator!(widget.controller?.text);
      setState(() {
        _validationError = error;
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    widget.controller?.removeListener(_handleTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasError = widget.errorText != null || _validationError != null;
    final errorMessage = widget.errorText ?? _validationError;

    // Colores adaptativos según el estado
    final borderColor = hasError
        ? scheme.error
        : _isFocused
            ? scheme.primary
            : scheme.outline.withValues(alpha: 0.3);

    final backgroundColor = widget.enabled
        ? scheme.surface.withValues(alpha: _isFocused ? 0.1 : 0.05)
        : scheme.surface.withValues(alpha: 0.02);

    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      textField: true,
      enabled: widget.enabled,
      focused: _isFocused,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          if (widget.label != null) ...[
            AnimatedDefaultTextStyle(
              duration: TerritoryTokens.durationFast,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hasError
                    ? scheme.error
                    : _isFocused
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w500,
              ) ?? const TextStyle(),
              child: Text(widget.label!),
            ),
            const SizedBox(height: TerritoryTokens.space8),
          ],

          // TextField con Aero styling
          AnimatedBuilder(
            animation: _focusAnimation,
            builder: (context, child) {
              return AeroSurface(
                level: widget.level,
                borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                padding: EdgeInsets.zero,
                child: AnimatedContainer(
                  duration: TerritoryTokens.durationFast,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
                    border: Border.all(
                      color: borderColor,
                      width: _isFocused ? 2 : 1,
                    ),
                    boxShadow: _isFocused
                        ? [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    onTap: widget.onTap,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    obscureText: widget.obscureText,
                    enabled: widget.enabled,
                    readOnly: widget.readOnly,
                    maxLines: widget.obscureText ? 1 : widget.maxLines,
                    minLines: widget.minLines,
                    maxLength: widget.maxLength,
                    inputFormatters: widget.inputFormatters,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: widget.enabled
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.5),
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      prefixIcon: widget.prefixIcon,
                      suffixIcon: widget.suffixIcon,
                      contentPadding: widget.contentPadding ??
                          const EdgeInsets.symmetric(
                            horizontal: TerritoryTokens.space16,
                            vertical: TerritoryTokens.space12,
                          ),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
              );
            },
          ),

          // Helper text, error text, or counter
          if (errorMessage != null || 
              widget.helperText != null || 
              (widget.showCounter && widget.maxLength != null)) ...[
            const SizedBox(height: TerritoryTokens.space4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Error or helper text
                Expanded(
                  child: AnimatedSwitcher(
                    duration: TerritoryTokens.durationFast,
                    child: errorMessage != null
                        ? _ErrorText(
                            key: const ValueKey('error'),
                            text: errorMessage,
                            color: scheme.error,
                          )
                        : widget.helperText != null
                            ? _HelperText(
                                key: const ValueKey('helper'),
                                text: widget.helperText!,
                                color: scheme.onSurfaceVariant,
                              )
                            : const SizedBox.shrink(),
                  ),
                ),
                // Counter
                if (widget.showCounter && widget.maxLength != null) ...[
                  const SizedBox(width: TerritoryTokens.space8),
                  _Counter(
                    current: _currentLength,
                    max: widget.maxLength!,
                    hasError: _currentLength > widget.maxLength!,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  final Color color;

  const _ErrorText({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: TerritoryTokens.space4),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _HelperText extends StatelessWidget {
  final String text;
  final Color color;

  const _HelperText({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: color.withValues(alpha: 0.7),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final int current;
  final int max;
  final bool hasError;

  const _Counter({
    required this.current,
    required this.max,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = hasError
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    return Text(
      '$current/$max',
      style: theme.textTheme.bodySmall?.copyWith(
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
