import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/user_model.dart';
import '../helpers/profile_formatters.dart';

class PersonalInfoCard extends StatelessWidget {
  final UserModel profile;

  const PersonalInfoCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final birthDateLabel = profile.birthDate != null
        ? DateFormat.yMMMd('es').format(profile.birthDate!)
        : '--';
    final ageLabel = profile.age?.toString() ?? '--';
    final bmiLabel = profile.bmi != null ? profile.bmi!.toStringAsFixed(1) : '--';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.badge, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Datos personales',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Nombre', value: profile.displayName),
            _InfoRow(label: 'Edad', value: ageLabel),
            _InfoRow(label: 'Fecha de nacimiento', value: birthDateLabel),
            _InfoRow(label: 'Peso', value: formatWeight(profile)),
            _InfoRow(label: 'Altura', value: formatHeight(profile)),
            _InfoRow(label: 'IMC', value: bmiLabel),
            if (profile.gender != null && profile.gender!.isNotEmpty)
              _InfoRow(label: 'Género', value: genderLabel(profile.gender)),
            _InfoRow(
              label: 'Sistema de medidas',
              value: profile.preferredUnits == 'imperial'
                  ? 'Imperial (mi, lb)'
                  : 'Métrico (km, kg)',
            ),
            if (profile.goalDescription != null &&
                profile.goalDescription!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Objetivo personal',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(profile.goalDescription!),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
