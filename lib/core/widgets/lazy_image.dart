import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../design_system/territory_tokens.dart';

/// Widget optimizado para cargar imágenes con lazy loading y cache
/// 
/// Uso:
/// ```dart
/// LazyImage(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 100,
///   height: 100,
/// )
/// ```
class LazyImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool fadeIn;
  final Duration fadeInDuration;
  final Duration? placeholderFadeDuration;
  final Color? backgroundColor;
  final Map<String, String>? httpHeaders;

  const LazyImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.fadeIn = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.placeholderFadeDuration,
    this.backgroundColor,
    this.httpHeaders,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      httpHeaders: httpHeaders,
      fadeInDuration: fadeIn ? fadeInDuration : Duration.zero,
      placeholderFadeInDuration: placeholderFadeDuration ?? fadeInDuration,
      placeholder: (context, url) {
        return placeholder ?? _DefaultPlaceholder(
          width: width,
          height: height,
          backgroundColor: backgroundColor,
        );
      },
      errorWidget: (context, url, error) {
        return errorWidget ?? _DefaultErrorWidget(
          width: width,
          height: height,
          backgroundColor: backgroundColor,
        );
      },
      memCacheWidth: width != null ? (width! * 2).toInt() : null,
      memCacheHeight: height != null ? (height! * 2).toInt() : null,
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// Placeholder shimmer por defecto
class _DefaultPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? backgroundColor;

  const _DefaultPlaceholder({
    this.width,
    this.height,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// Widget de error por defecto
class _DefaultErrorWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? backgroundColor;

  const _DefaultErrorWidget({
    this.width,
    this.height,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.errorContainer.withValues(alpha: 0.1),
      ),
      child: Icon(
        Icons.broken_image_outlined,
        size: 32,
        color: theme.colorScheme.error.withValues(alpha: 0.5),
      ),
    );
  }
}

/// Avatar circular con lazy loading
class LazyAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? placeholder;
  final Color? backgroundColor;
  final String? fallbackText;

  const LazyAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.placeholder,
    this.backgroundColor,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? theme.colorScheme.primaryContainer,
        child: fallbackText != null
            ? Text(
                fallbackText!,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              )
            : Icon(
                Icons.person,
                size: radius,
                color: theme.colorScheme.onPrimaryContainer,
              ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
      child: ClipOval(
        child: LazyImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: placeholder ?? Container(
            width: radius * 2,
            height: radius * 2,
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget para imágenes de fondo con parallax opcional
class LazyBackgroundImage extends StatelessWidget {
  final String imageUrl;
  final Widget? child;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final Color? overlayColor;
  final double overlayOpacity;

  const LazyBackgroundImage({
    super.key,
    required this.imageUrl,
    this.child,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.overlayColor,
    this.overlayOpacity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        LazyImage(
          imageUrl: imageUrl,
          fit: fit,
        ),
        if (overlayColor != null)
          Container(
            color: overlayColor!.withValues(alpha: overlayOpacity),
          ),
        if (child != null) child!,
      ],
    );
  }
}

/// Galería de imágenes con lazy loading
class LazyImageGrid extends StatelessWidget {
  final List<String> imageUrls;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final void Function(String imageUrl)? onTap;

  const LazyImageGrid({
    super.key,
    required this.imageUrls,
    this.crossAxisCount = 3,
    this.mainAxisSpacing = TerritoryTokens.space8,
    this.crossAxisSpacing = TerritoryTokens.space8,
    this.childAspectRatio = 1.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        final imageUrl = imageUrls[index];
        return GestureDetector(
          onTap: onTap != null ? () => onTap!(imageUrl) : null,
          child: LazyImage(
            imageUrl: imageUrl,
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
