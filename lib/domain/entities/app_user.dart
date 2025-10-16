import 'package:equatable/equatable.dart';

/// Entidad de usuario del dominio (independiente de la implementación)
class AppUser extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool isEmailVerified;
  final List<String> providers;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
    this.providers = const [],
    this.createdAt,
    this.lastLoginAt,
  });

  bool get hasEmailProvider => providers.contains('password');
  bool get hasGoogleProvider => providers.contains('google.com');
  bool get hasMultipleProviders => providers.length > 1;
  
  String get initials {
    final names = displayName.trim().split(' ');
    if (names.isEmpty) return '';
    
    if (names.length == 1) {
      return names.first.substring(0, 1).toUpperCase();
    }
    
    return '${names.first.substring(0, 1)}${names.last.substring(0, 1)}'
        .toUpperCase();
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    List<String>? providers,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      providers: providers ?? this.providers,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    photoUrl,
    isEmailVerified,
    providers,
    createdAt,
    lastLoginAt,
  ];
}
