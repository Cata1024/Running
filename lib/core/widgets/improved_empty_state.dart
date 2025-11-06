import 'package:flutter/material.dart';
import '../design_system/territory_tokens.dart';
import '../animations/animation_helpers.dart';

/// Empty state mejorado con animaciones y mejor UX
class ImprovedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Color? iconColor;
  final bool showAnimation;
  
  const ImprovedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconColor,
    this.showAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    
    Widget content = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TerritoryTokens.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono con animación
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    effectiveIconColor.withValues(alpha: 0.2),
                    effectiveIconColor.withValues(alpha: 0.1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: effectiveIconColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 60,
                color: effectiveIconColor,
              ),
            ),
            
            const SizedBox(height: TerritoryTokens.space32),
            
            // Título
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: TerritoryTokens.space12),
            
            // Mensaje
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            // Acciones
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: TerritoryTokens.space32),
              
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
            
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: TerritoryTokens.space12),
              
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
    
    // Aplicar animaciones si está habilitado
    if (showAnimation) {
      content = AnimationHelpers.fadeSlideIn(
        duration: AnimationHelpers.slow,
        child: content,
      );
    }
    
    return content;
  }
}

/// Empty state específico para listas de carreras
class EmptyRunsState extends StatelessWidget {
  final VoidCallback? onStartRun;
  
  const EmptyRunsState({
    super.key,
    this.onStartRun,
  });

  @override
  Widget build(BuildContext context) {
    return ImprovedEmptyState(
      icon: Icons.directions_run,
      title: '¡Es hora de correr!',
      message: 'Aún no has registrado ninguna carrera.\nInicia tu primera carrera y comienza a conquistar territorio.',
      actionLabel: 'Comenzar Carrera',
      onAction: onStartRun,
      iconColor: Theme.of(context).colorScheme.primary,
    );
  }
}

/// Empty state para logros sin desbloquear
class EmptyAchievementsState extends StatelessWidget {
  final VoidCallback? onViewAll;
  
  const EmptyAchievementsState({
    super.key,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return ImprovedEmptyState(
      icon: Icons.emoji_events_outlined,
      title: 'Logros por desbloquear',
      message: 'Completa carreras para desbloquear tus primeros logros\ny ganar experiencia.',
      actionLabel: 'Ver Todos los Logros',
      onAction: onViewAll,
      iconColor: Colors.amber,
    );
  }
}

/// Empty state para territorio sin cubrir
class EmptyTerritoryState extends StatelessWidget {
  final VoidCallback? onExplore;
  
  const EmptyTerritoryState({
    super.key,
    this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return ImprovedEmptyState(
      icon: Icons.explore_outlined,
      title: 'Territorio sin explorar',
      message: 'Sal a correr y comienza a marcar tu territorio.\n¡Cada metro cuenta!',
      actionLabel: 'Explorar Mapa',
      onAction: onExplore,
      iconColor: Colors.green,
    );
  }
}

/// Empty state para búsquedas sin resultados
class EmptySearchState extends StatelessWidget {
  final String? searchQuery;
  final VoidCallback? onClearSearch;
  
  const EmptySearchState({
    super.key,
    this.searchQuery,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return ImprovedEmptyState(
      icon: Icons.search_off,
      title: 'Sin resultados',
      message: searchQuery != null
          ? 'No encontramos resultados para "$searchQuery".\nIntenta con otros términos.'
          : 'No encontramos resultados.\nIntenta con otros términos de búsqueda.',
      actionLabel: onClearSearch != null ? 'Limpiar Búsqueda' : null,
      onAction: onClearSearch,
      iconColor: Colors.grey,
    );
  }
}

/// Loading state animado mejorado
class ImprovedLoadingState extends StatelessWidget {
  final String? message;
  final Color? color;
  
  const ImprovedLoadingState({
    super.key,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
    
    return Center(
      child: AnimationHelpers.fadeSlideIn(
        duration: AnimationHelpers.fast,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Spinner personalizado
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
              ),
            ),
            
            if (message != null) ...[
              const SizedBox(height: TerritoryTokens.space24),
              
              Text(
                message!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader para cards
class SkeletonCard extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  
  const SkeletonCard({
    super.key,
    this.height = 100,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveRadius = borderRadius ?? BorderRadius.circular(TerritoryTokens.radiusMedium);
    
    return SizedBox(
      height: height,
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: effectiveRadius,
        ),
        child: AnimationHelpers.shimmer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: effectiveRadius,
            ),
          ),
        ),
      ),
    );
  }
}

/// Lista de skeleton cards
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;
  
  const SkeletonList({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 100,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(TerritoryTokens.space16),
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) {
        return SkeletonCard(height: itemHeight);
      },
    );
  }
}
