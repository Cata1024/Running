import 'package:flutter/material.dart';
import '../design_system/territory_tokens.dart';
import 'aero_button.dart';

/// Widget para mostrar estados de error
class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  
  const ErrorState({
    super.key,
    this.title = 'Algo salió mal',
    required this.message,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TerritoryTokens.space48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 120,
              color: scheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: TerritoryTokens.space24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TerritoryTokens.space12),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: TerritoryTokens.space32),
              AeroButton(
                onPressed: onRetry,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Reintentar'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
