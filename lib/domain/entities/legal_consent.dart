import 'dart:convert';

class LegalConsent {
  final String termsVersion;
  final String privacyVersion;
  final bool locationConsent;
  final bool analyticsConsent;
  final bool marketingConsent;
  final bool ageConfirmed;
  final DateTime acceptedAt;

  const LegalConsent({
    required this.termsVersion,
    required this.privacyVersion,
    required this.locationConsent,
    required this.analyticsConsent,
    required this.marketingConsent,
    required this.ageConfirmed,
    required this.acceptedAt,
  });

  factory LegalConsent.initial() => LegalConsent(
        termsVersion: '',
        privacyVersion: '',
        locationConsent: false,
        analyticsConsent: false,
        marketingConsent: false,
        ageConfirmed: false,
        acceptedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  LegalConsent copyWith({
    String? termsVersion,
    String? privacyVersion,
    bool? locationConsent,
    bool? analyticsConsent,
    bool? marketingConsent,
    bool? ageConfirmed,
    DateTime? acceptedAt,
  }) {
    return LegalConsent(
      termsVersion: termsVersion ?? this.termsVersion,
      privacyVersion: privacyVersion ?? this.privacyVersion,
      locationConsent: locationConsent ?? this.locationConsent,
      analyticsConsent: analyticsConsent ?? this.analyticsConsent,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      ageConfirmed: ageConfirmed ?? this.ageConfirmed,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }

  bool get isEmpty => termsVersion.isEmpty || privacyVersion.isEmpty;

  bool isCompliant({
    required String requiredTermsVersion,
    required String requiredPrivacyVersion,
  }) {
    return termsVersion == requiredTermsVersion &&
        privacyVersion == requiredPrivacyVersion &&
        locationConsent &&
        ageConfirmed;
  }

  bool requiresRenewal({
    required String requiredTermsVersion,
    required String requiredPrivacyVersion,
  }) {
    if (isEmpty) return true;
    if (termsVersion != requiredTermsVersion) return true;
    if (privacyVersion != requiredPrivacyVersion) return true;
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'termsVersion': termsVersion,
      'privacyVersion': privacyVersion,
      'locationConsent': locationConsent,
      'analyticsConsent': analyticsConsent,
      'marketingConsent': marketingConsent,
      'ageConfirmed': ageConfirmed,
      'acceptedAt': acceptedAt.toUtc().toIso8601String(),
    };
  }

  static LegalConsent fromJson(Map<String, dynamic> json) {
    return LegalConsent(
      termsVersion: json['termsVersion'] as String? ?? '',
      privacyVersion: json['privacyVersion'] as String? ?? '',
      locationConsent: json['locationConsent'] as bool? ?? false,
      analyticsConsent: json['analyticsConsent'] as bool? ?? false,
      marketingConsent: json['marketingConsent'] as bool? ?? false,
      ageConfirmed: json['ageConfirmed'] as bool? ?? false,
      acceptedAt: DateTime.tryParse(json['acceptedAt'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  String toEncodedJson() => jsonEncode(toJson());

  static LegalConsent fromEncodedJson(String value) {
    return fromJson(jsonDecode(value) as Map<String, dynamic>);
  }
}

class LegalConsentState {
  final LegalConsent consent;
  final bool isLoaded;

  const LegalConsentState({
    required this.consent,
    required this.isLoaded,
  });

  factory LegalConsentState.initial() => LegalConsentState(
        consent: LegalConsent.initial(),
        isLoaded: false,
      );

  LegalConsentState copyWith({
    LegalConsent? consent,
    bool? isLoaded,
  }) {
    return LegalConsentState(
      consent: consent ?? this.consent,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}
