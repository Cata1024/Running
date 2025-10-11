import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;
  final IconData fallbackIcon;

  const ProfileAvatar({
    super.key,
    this.photoUrl,
    this.radius = 22,
    this.fallbackIcon = Icons.person_outline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.6),
      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
          ? NetworkImage(photoUrl!)
          : null,
      child: photoUrl == null || photoUrl!.isEmpty
          ? Icon(fallbackIcon, color: colorScheme.primary)
          : null,
    );
  }
}
