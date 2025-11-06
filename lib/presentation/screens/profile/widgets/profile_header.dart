import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/territory_tokens.dart';
import 'profile_avatar.dart';
import 'profile_view_model.dart';
import '../../../providers/optimized_providers.dart';

class ProfileHeader extends ConsumerWidget {
  final ProfileViewModel profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final displayName = ref.watch(userDisplayNameProvider) ?? profile.displayName;
    final photoUrl = ref.watch(userPhotoUrlProvider) ?? profile.photoUrl;
    final lastActivity = ref.watch(userLastActivityProvider) ?? profile.lastActivityAt;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileAvatar(photoUrl: photoUrl, initials: profile.initials),
        const SizedBox(width: TerritoryTokens.space16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (profile.email != null && profile.email!.isNotEmpty) ...[
                const SizedBox(height: TerritoryTokens.space4),
                Text(
                  profile.email!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (lastActivity != null) ...[
                const SizedBox(height: TerritoryTokens.space8),
                Text(
                  "Última actividad: ${_formatDate(lastActivity)}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}
