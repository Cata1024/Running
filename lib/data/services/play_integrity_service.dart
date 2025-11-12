import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Wrapper simple para solicitar tokens de Play Integrity desde Flutter.
///
/// Implementa un cache temporal para evitar solicitar el token en cada request
/// de red, dado que la API puede tardar varios cientos de milisegundos.
class PlayIntegrityService {
  static const _channel = MethodChannel('play_integrity');
  static const _cacheTtl = Duration(minutes: 5);

  String? _cachedToken;
  DateTime? _lastFetch;

  /// Solicita un token de Play Integrity si la plataforma es Android (no web).
  /// Retorna `null` en otras plataformas o cuando ocurre un error.
  Future<String?> getIntegrityToken() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    final now = DateTime.now();
    if (_cachedToken != null && _lastFetch != null) {
      final elapsed = now.difference(_lastFetch!);
      if (elapsed < _cacheTtl) {
        return _cachedToken;
      }
    }

    final nonce = _generateNonce();

    try {
      final token = await _channel.invokeMethod<String>(
        'requestIntegrityToken',
        {
          'nonce': nonce,
        },
      );

      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
        _lastFetch = now;
      }

      return token;
    } on PlatformException catch (error, stackTrace) {
      debugPrint('PlayIntegrityService error: ${error.message}\n$stackTrace');
      return null;
    } catch (error, stackTrace) {
      debugPrint('PlayIntegrityService unexpected error: $error\n$stackTrace');
      return null;
    }
  }

  String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
