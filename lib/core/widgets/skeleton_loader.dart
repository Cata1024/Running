import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../design_system/territory_tokens.dart';

/// Skeleton loader genérico con shimmer effect
/// 
/// Uso:
/// ```dart
/// SkeletonLoader(
///   width: 100,
///   height: 20,
///   borderRadius: BorderRadius.circular(8),
/// )
/// ```
class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.surfaceContainerHigh,
      highlightColor: isDark
          ? theme.colorScheme.surfaceContainerHigh
          : theme.colorScheme.surface,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius ?? BorderRadius.circular(TerritoryTokens.radiusSmall),
        ),
      ),
    );
  }
}

/// Skeleton circular para avatares
class SkeletonCircle extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry? margin;

  const SkeletonCircle({
    super.key,
    this.size = 40,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.surfaceContainerHigh,
      highlightColor: isDark
          ? theme.colorScheme.surfaceContainerHigh
          : theme.colorScheme.surface,
      child: Container(
        width: size,
        height: size,
        margin: margin,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Skeleton para cards de carrera
class RunCardSkeleton extends StatelessWidget {
  const RunCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: TerritoryTokens.space12),
      padding: const EdgeInsets.all(TerritoryTokens.space16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonCircle(size: 48),
              const SizedBox(width: TerritoryTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: double.infinity,
                      height: 16,
                      borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
                    ),
                    const SizedBox(height: TerritoryTokens.space8),
                    SkeletonLoader(
                      width: 120,
                      height: 14,
                      borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TerritoryTokens.space16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SkeletonStat(),
              _SkeletonStat(),
              _SkeletonStat(),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonStat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SkeletonLoader(
          width: 60,
          height: 20,
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
        ),
        const SizedBox(height: TerritoryTokens.space4),
        SkeletonLoader(
          width: 40,
          height: 12,
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
        ),
      ],
    );
  }
}

/// Skeleton para perfil de usuario
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: TerritoryTokens.space32),
        const SkeletonCircle(size: 100),
        const SizedBox(height: TerritoryTokens.space16),
        SkeletonLoader(
          width: 200,
          height: 24,
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
        ),
        const SizedBox(height: TerritoryTokens.space8),
        SkeletonLoader(
          width: 150,
          height: 16,
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
        ),
        const SizedBox(height: TerritoryTokens.space32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ProfileStatSkeleton(),
            _ProfileStatSkeleton(),
            _ProfileStatSkeleton(),
          ],
        ),
      ],
    );
  }
}

class _ProfileStatSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SkeletonLoader(
          width: 70,
          height: 28,
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
        ),
        const SizedBox(height: TerritoryTokens.space8),
        SkeletonLoader(
          width: 50,
          height: 14,
          borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
        ),
      ],
    );
  }
}

/// Skeleton list para historial
class HistoryListSkeleton extends StatelessWidget {
  final int itemCount;

  const HistoryListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const RunCardSkeleton(),
    );
  }
}

/// Skeleton para texto de párrafo
class TextSkeleton extends StatelessWidget {
  final int lines;
  final double lineHeight;
  final double? lastLineWidth;

  const TextSkeleton({
    super.key,
    this.lines = 3,
    this.lineHeight = 16,
    this.lastLineWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < lines - 1 ? TerritoryTokens.space8 : 0,
          ),
          child: SkeletonLoader(
            width: isLast && lastLineWidth != null ? lastLineWidth : double.infinity,
            height: lineHeight,
            borderRadius: BorderRadius.circular(TerritoryTokens.radiusSmall),
          ),
        );
      }),
    );
  }
}

/// Skeleton para mapa de carrera
class MapSkeleton extends StatelessWidget {
  final double? height;

  const MapSkeleton({
    super.key,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: height ?? 300,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
      ),
      child: Stack(
        children: [
          Shimmer.fromColors(
            baseColor: isDark
                ? theme.colorScheme.surfaceContainerHighest
                : theme.colorScheme.surfaceContainerHigh,
            highlightColor: isDark
                ? theme.colorScheme.surfaceContainerHigh
                : theme.colorScheme.surface,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.map_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton para botón
class ButtonSkeleton extends StatelessWidget {
  final double? width;
  final double height;

  const ButtonSkeleton({
    super.key,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width ?? double.infinity,
      height: height,
      borderRadius: BorderRadius.circular(TerritoryTokens.radiusMedium),
    );
  }
}
