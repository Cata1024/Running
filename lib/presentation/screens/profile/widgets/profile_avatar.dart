import 'package:flutter/material.dart';

import '../../../../core/widgets/lazy_image.dart';
import '../../../providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      final AsyncValue<Map<String, String>> headersAsync =
          ref.watch(apiAuthHeadersProvider);
      final Map<String, String>? headers = headersAsync.when(
        data: (value) => value,
        loading: () => null,
        error: (_, __) => null,
      );
      return CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.primary,
        child: ClipOval(
          child: LazyImage(
            imageUrl: photoUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            httpHeaders: headers,
            placeholder: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            errorWidget: Center(
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
      );
    }

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
}
