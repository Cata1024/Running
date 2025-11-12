import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/lazy_image.dart';
import '../../../providers/app_providers.dart';

class ProfileAvatar extends ConsumerWidget {
  final String? photoUrl;
  final String initials;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.initials,
    this.radius = 36,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (photoUrl == null || photoUrl!.isEmpty) {
      return _buildInitialsAvatar(theme);
    }

    final headersAsync = ref.watch(apiAuthHeadersProvider);
    final headers = headersAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );

    return _buildImageAvatar(
      theme: theme,
      headers: headers,
      showLoadingOverlay: headersAsync.isLoading && headers == null,
    );
  }

  Widget _buildInitialsAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary,
      child: Text(
        initials,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildImageAvatar({
    required ThemeData theme,
    Map<String, String>? headers,
    bool showLoadingOverlay = false,
  }) {
    return SizedBox( // mantener dimensiones consistentes para overlays
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: theme.colorScheme.primary,
            child: ClipOval(
              child: LazyImage(
                key: ValueKey('${photoUrl}_${headers?['Authorization'] ?? ''}'),
                imageUrl: photoUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                httpHeaders: headers,
                placeholder: Container(
                  width: radius * 2,
                  height: radius * 2,
                  color: theme.colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: radius,
                    height: radius,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                errorWidget: Container(
                  width: radius * 2,
                  height: radius * 2,
                  color: theme.colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (showLoadingOverlay)
            SizedBox(
              width: radius,
              height: radius,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
