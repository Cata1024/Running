import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/legal_constants.dart';
import '../../../core/design_system/territory_tokens.dart';
import '../../../core/widgets/aero_surface.dart';
import '../../providers/app_providers.dart';
import '../../../domain/entities/legal_consent.dart';

class LegalConsentScreen extends ConsumerStatefulWidget {
  const LegalConsentScreen({super.key});

  @override
  ConsumerState<LegalConsentScreen> createState() => _LegalConsentScreenState();
}

class _LegalConsentScreenState extends ConsumerState<LegalConsentScreen> {
  late bool _termsAccepted;
  late bool _locationConsent;
  late bool _analyticsConsent;
  late bool _marketingConsent;
  late bool _ageConfirmed;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final consent = ref.read(legalConsentProvider);
    _termsAccepted = consent.termsVersion == LegalConstants.termsVersion &&
        consent.privacyVersion == LegalConstants.privacyVersion;
    _locationConsent = consent.locationConsent;
    _analyticsConsent = consent.analyticsConsent;
    _marketingConsent = consent.marketingConsent;
    _ageConfirmed = consent.ageConfirmed;
  }

  bool get _canSubmit =>
      _termsAccepted && _locationConsent && _ageConfirmed && !_saving;

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el enlace. Intenta nuevamente.'),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _saving = true);
    final notifier = ref.read(legalConsentProvider.notifier);
    final consent = LegalConsent(
      termsVersion: LegalConstants.termsVersion,
      privacyVersion: LegalConstants.privacyVersion,
      locationConsent: _locationConsent,
      analyticsConsent: _analyticsConsent,
      marketingConsent: _marketingConsent,
      ageConfirmed: _ageConfirmed,
      acceptedAt: DateTime.now().toUtc(),
    );
    await notifier.saveConsent(consent);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Consentimiento actualizado.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/map');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consentimiento Legal'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TerritoryTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para cumplir con la normativa de protección de datos, necesitamos tu autorización explícita.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: TerritoryTokens.space16),
            AeroSurface(
              level: AeroLevel.medium,
              borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
              padding: const EdgeInsets.all(TerritoryTokens.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Documentos legales'),
                    subtitle: const Text(
                      'Revisa la Política de Privacidad y los Términos de Uso antes de continuar.',
                    ),
                  ),
                  const SizedBox(height: TerritoryTokens.space8),
                  Wrap(
                    spacing: TerritoryTokens.space12,
                    runSpacing: TerritoryTokens.space12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _launch(LegalConstants.privacyUrl),
                        icon: const Icon(Icons.privacy_tip_outlined),
                        label: const Text('Política de Privacidad'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _launch(LegalConstants.termsUrl),
                        icon: const Icon(Icons.rule_folder_outlined),
                        label: const Text('Términos y Condiciones'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: TerritoryTokens.space16),
            AeroSurface(
              level: AeroLevel.medium,
              borderRadius: BorderRadius.circular(TerritoryTokens.radiusLarge),
              padding: const EdgeInsets.all(TerritoryTokens.space16),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _termsAccepted,
                    onChanged: (value) {
                      setState(() => _termsAccepted = value ?? false);
                    },
                    title: const Text('Acepto los Términos y la Política de Privacidad'),
                    subtitle: const Text(
                      'Esta autorización es obligatoria para usar la aplicación.',
                    ),
                  ),
                  CheckboxListTile(
                    value: _locationConsent,
                    onChanged: (value) {
                      setState(() => _locationConsent = value ?? false);
                    },
                    title: const Text('Autorizo el uso de mi ubicación en tiempo real'),
                    subtitle: const Text(
                      'Usamos tu ubicación para trazar tus carreras y calcular territorio.',
                    ),
                  ),
                  CheckboxListTile(
                    value: _ageConfirmed,
                    onChanged: (value) {
                      setState(() => _ageConfirmed = value ?? false);
                    },
                    title: const Text('Confirmo que tengo 13 años o más'),
                    subtitle: const Text(
                      'Si eres menor, debes contar con autorización de tus padres o tutores.',
                    ),
                  ),
                  const Divider(height: TerritoryTokens.space24),
                  CheckboxListTile(
                    value: _analyticsConsent,
                    onChanged: (value) {
                      setState(() => _analyticsConsent = value ?? false);
                    },
                    title: const Text('Autorizo el uso de datos anónimos para analítica'),
                    subtitle: const Text(
                      'Esta opción es voluntaria y nos ayuda a mejorar la app.',
                    ),
                  ),
                  CheckboxListTile(
                    value: _marketingConsent,
                    onChanged: (value) {
                      setState(() => _marketingConsent = value ?? false);
                    },
                    title: const Text('Deseo recibir comunicaciones y novedades'),
                    subtitle: const Text(
                      'Puedes revocar esta autorización en cualquier momento.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TerritoryTokens.space24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canSubmit ? _submit : null,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_user),
                label: Text(_saving ? 'Guardando...' : 'Aceptar y continuar'),
              ),
            ),
            const SizedBox(height: TerritoryTokens.space12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  final subject = Uri.encodeComponent('Solicitud derechos ARCO - Territory Run');
                  final body = Uri.encodeComponent(
                    'Hola equipo Territory Run,\n\nDeseo ejercer mis derechos de habeas data. Mi solicitud es:\n\n- [Acceso / Actualización / Supresión / Revocatoria]\n\nDatos adicionales:\nNombre completo:\nCorreo registrado:\nDescripción de la solicitud:\n\nGracias.',
                  );
                  final uri = Uri.parse('mailto:${LegalConstants.dpoEmail}?subject=$subject&body=$body');
                  await launchUrl(uri);
                },
                icon: const Icon(Icons.mail_outline),
                label: const Text('Solicitar acceso o eliminación de datos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
