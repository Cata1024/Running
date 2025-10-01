import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerUtils {
  // Genera un ícono de marcador circular con un emoji (por ejemplo, 🏃)
  static Future<BitmapDescriptor> runnerMarker({
    double size = 64,
    Color bg = const Color(0xFF1E88E5),
    String emoji = '🏃',
  }) async {
    // En Web con renderer HTML, toImage no está soportado; usar fallback
    if (kIsWeb) {
      // Heurística simple para elegir un hue similar al color de fondo
      final v = bg.value & 0xFFFFFF;
      if (v == 0x1E88E5) {
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      }
      if (v == 0xFF8F00 || v == 0xFFA000 || v == 0xFF6D00) {
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      }
      return BitmapDescriptor.defaultMarker;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = bg;
    final center = Offset(size / 2, size / 2);

    // Círculo de fondo
    canvas.drawCircle(center, size / 2, paint);

    // Dibuja el emoji centrado
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: size * 0.55),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(minWidth: 0, maxWidth: size);
    final offset = Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2);
    textPainter.paint(canvas, offset);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }
}
