import '../../../models/user_model.dart';

String formatWeight(UserModel profile) {
  if (profile.weightKg == null) return '--';
  if (profile.preferredUnits == 'imperial') {
    final pounds = profile.weightKg! * 2.2046226218;
    return '${pounds.toStringAsFixed(1)} lb';
  }
  return '${profile.weightKg!.toStringAsFixed(1)} kg';
}

String formatHeight(UserModel profile) {
  if (profile.heightCm == null) return '--';
  if (profile.preferredUnits == 'imperial') {
    final totalInches = profile.heightCm! / 2.54;
    final feet = totalInches ~/ 12;
    final inches = totalInches - (feet * 12);
    if (feet > 0) {
      return '${feet.toString()} ft ${inches.toStringAsFixed(1)} in';
    }
    return '${inches.toStringAsFixed(1)} in';
  }
  return '${profile.heightCm} cm';
}

String genderLabel(String? code) {
  switch (code) {
    case 'female':
      return 'Femenino';
    case 'male':
      return 'Masculino';
    case 'non_binary':
      return 'No binario';
    case 'prefer_not':
      return 'Prefiero no decirlo';
  }
  return code ?? '--';
}
