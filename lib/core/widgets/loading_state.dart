import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'aero_surface.dart';

/// Widget para mostrar estados de carga
class LoadingState extends StatelessWidget {
  final String? message;
  
  const LoadingState({super.key, this.message});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: AeroSurface(
        level: AeroLevel.medium,
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: AppTheme.space16),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
