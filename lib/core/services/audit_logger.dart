import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio simple para registrar auditoría en un archivo local persistente.
class AuditLogger {
  AuditLogger();

  static const String _fileName = 'audit_log.jsonl';

  Future<File> _resolveFile() async {
    if (kIsWeb) {
      throw UnsupportedError('AuditLogger file storage is not supported on web');
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_fileName');
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    return file;
  }

  Future<void> log(String type, Map<String, dynamic> payload) async {
    try {
      if (kIsWeb) {
        debugPrint('AuditLogger skip (web) event: $type');
        return;
      }
      final file = await _resolveFile();
      final record = <String, dynamic>{
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'type': type,
        'payload': payload,
      };
      await file.writeAsString('${jsonEncode(record)}\n', mode: FileMode.append, flush: true);
    } catch (e, st) {
      debugPrint('AuditLogger error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<List<Map<String, dynamic>>> readAll() async {
    try {
      if (kIsWeb) {
        return const [];
      }
      final file = await _resolveFile();
      final lines = await file.readAsLines();
      return lines
          .where((line) => line.trim().isNotEmpty)
          .map<Map<String, dynamic>>((line) {
        try {
          final decoded = jsonDecode(line);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {}
        return {
          'raw': line,
        };
      }).toList();
    } catch (e, st) {
      debugPrint('AuditLogger read error: $e');
      debugPrintStack(stackTrace: st);
      return const [];
    }
  }
}

/// Provider global para el logger de auditoría.
final auditLoggerProvider = Provider<AuditLogger>((ref) {
  final logger = AuditLogger();
  return logger;
});
