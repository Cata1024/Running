import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CompleteProfileForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final TextEditingController goalController;
  final TextEditingController photoUrlController;
  final DateTime? birthDate;
  final String? selectedGender;
  final String preferredUnits;
  final bool isSubmitting;
  final VoidCallback onPickBirthDate;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<String> onUnitsChanged;

  const CompleteProfileForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.weightController,
    required this.heightController,
    required this.goalController,
    required this.photoUrlController,
    required this.birthDate,
    required this.selectedGender,
    required this.preferredUnits,
    required this.isSubmitting,
    required this.onPickBirthDate,
    required this.onGenderChanged,
    required this.onUnitsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = birthDate != null
        ? DateFormat.yMMMMd('es').format(birthDate!)
        : 'Selecciona tu fecha de nacimiento';

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Bienvenido! Necesitamos algunos datos para personalizar tu experiencia.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa tu nombre';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: isSubmitting ? null : onPickBirthDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha de nacimiento',
                border: OutlineInputBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateLabel),
                  const Icon(Icons.calendar_today_outlined),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedGender,
            items: const [
              DropdownMenuItem(value: 'female', child: Text('Femenino')),
              DropdownMenuItem(value: 'male', child: Text('Masculino')),
              DropdownMenuItem(value: 'non_binary', child: Text('No binario')),
              DropdownMenuItem(value: 'prefer_not', child: Text('Prefiero no decirlo')),
            ],
            onChanged: isSubmitting ? null : onGenderChanged,
            decoration: const InputDecoration(
              labelText: 'Género (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: preferredUnits,
            items: const [
              DropdownMenuItem(value: 'metric', child: Text('Sistema métrico (km, kg)')),
              DropdownMenuItem(value: 'imperial', child: Text('Sistema imperial (mi, lb)')),
            ],
            onChanged: isSubmitting
                ? null
                : (value) {
                    if (value != null) {
                      onUnitsChanged(value);
                    }
                  },
            decoration: const InputDecoration(
              labelText: 'Sistema de medidas',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso (kg)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Altura (cm)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: goalController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Objetivo personal (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: photoUrlController,
            decoration: const InputDecoration(
              labelText: 'Foto de perfil (URL, opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
