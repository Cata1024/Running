/// Datos completos para el registro de un nuevo usuario
/// 
/// Esta entidad encapsula toda la información recopilada durante el onboarding
class RegistrationData {
  // Datos de autenticación (opcionales si es social login)
  final String? email;
  final String? password;
  
  // Datos personales básicos
  final String displayName;
  final DateTime birthDate;
  final String gender; // 'male', 'female', 'other', 'prefer_not_say'
  
  // Datos físicos
  final double weightKg;
  final int heightCm;
  
  // Objetivos y preferencias
  final String goalType; // 'fitness', 'weight_loss', 'competition', 'fun'
  final double weeklyDistanceGoal; // km por semana
  final String? goalDescription; // Descripción personalizada opcional
  
  // Preferencias
  final String preferredUnits; // 'metric' o 'imperial'
  
  // Método de autenticación usado
  final AuthMethod authMethod;

  const RegistrationData({
    this.email,
    this.password,
    required this.displayName,
    required this.birthDate,
    required this.gender,
    required this.weightKg,
    required this.heightCm,
    required this.goalType,
    required this.weeklyDistanceGoal,
    this.goalDescription,
    this.preferredUnits = 'metric',
    required this.authMethod,
  });

  /// Validar que los datos estén completos
  bool get isValid {
    // Si es email/password, deben estar presentes
    if (authMethod == AuthMethod.emailPassword) {
      if (email == null || email!.isEmpty) return false;
      if (password == null || password!.isEmpty) return false;
    }
    
    // Validaciones básicas
    if (displayName.trim().isEmpty) return false;
    if (weightKg <= 0 || weightKg > 500) return false;
    if (heightCm <= 0 || heightCm > 300) return false;
    if (weeklyDistanceGoal < 0 || weeklyDistanceGoal > 500) return false;
    
    // Edad válida (debe tener al menos 13 años)
    final age = DateTime.now().year - birthDate.year;
    if (age < 13) return false;
    
    return true;
  }

  /// Convertir a mapa para enviar a Firebase
  Map<String, dynamic> toProfileData() {
    return {
      if (email != null) 'email': email,
      'displayName': displayName,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'goalType': goalType,
      'weeklyDistanceGoal': weeklyDistanceGoal,
      if (goalDescription != null) 'goalDescription': goalDescription,
      'preferredUnits': preferredUnits,
      'createdAt': DateTime.now().toIso8601String(),
      'level': 1,
      'experience': 0,
      'totalRuns': 0,
      'totalDistance': 0.0,
      'totalTime': 0,
      'achievements': [],
    };
  }

  RegistrationData copyWith({
    String? email,
    String? password,
    String? displayName,
    DateTime? birthDate,
    String? gender,
    double? weightKg,
    int? heightCm,
    String? goalType,
    double? weeklyDistanceGoal,
    String? goalDescription,
    String? preferredUnits,
    AuthMethod? authMethod,
  }) {
    return RegistrationData(
      email: email ?? this.email,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      goalType: goalType ?? this.goalType,
      weeklyDistanceGoal: weeklyDistanceGoal ?? this.weeklyDistanceGoal,
      goalDescription: goalDescription ?? this.goalDescription,
      preferredUnits: preferredUnits ?? this.preferredUnits,
      authMethod: authMethod ?? this.authMethod,
    );
  }
}

/// Métodos de autenticación disponibles
enum AuthMethod {
  emailPassword,
  google,
  apple,
  facebook,
}

/// Extensión para obtener el nombre legible del método
extension AuthMethodExtension on AuthMethod {
  String get displayName {
    switch (this) {
      case AuthMethod.emailPassword:
        return 'Email';
      case AuthMethod.google:
        return 'Google';
      case AuthMethod.apple:
        return 'Apple';
      case AuthMethod.facebook:
        return 'Facebook';
    }
  }
  
  String get icon {
    switch (this) {
      case AuthMethod.emailPassword:
        return 'email';
      case AuthMethod.google:
        return 'google';
      case AuthMethod.apple:
        return 'apple';
      case AuthMethod.facebook:
        return 'facebook';
    }
  }
}
