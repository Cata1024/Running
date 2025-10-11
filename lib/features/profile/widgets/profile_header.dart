import 'package:flutter/material.dart';

import '../../../models/user_model.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage:
              profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
          child: profile.photoUrl == null
              ? Icon(Icons.person, color: colorScheme.onPrimaryContainer, size: 32)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.displayName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                profile.email,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
