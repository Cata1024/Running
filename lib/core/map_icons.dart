import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapIconsBundle {
  const MapIconsBundle({
    required this.runner,
    required this.start,
    required this.finish,
  });

  final BitmapDescriptor runner;
  final BitmapDescriptor start;
  final BitmapDescriptor finish;
}

class MapIcons {
  static Future<MapIconsBundle> load() =>
      _bundle ??= _createDefaultBundle();

  static Future<MapIconsBundle>? _bundle;

  static Future<MapIconsBundle> _createDefaultBundle() async {
    final runner = await _renderIcon(
      icon: Icons.directions_run,
      foreground: const Color(0xFFFB8C00),
      background: Colors.white,
      size: 112,
    );
    final start = await _renderIcon(
      icon: Icons.play_arrow_rounded,
      foreground: const Color(0xFF2E7D32),
      background: Colors.white,
      size: 108,
    );
    final finish = await _renderIcon(
      icon: Icons.flag,
      foreground: const Color(0xFFC62828),
      background: Colors.white,
      size: 108,
    );

    return MapIconsBundle(
      runner: runner,
      start: start,
      finish: finish,
    );
  }

  static Future<BitmapDescriptor> custom({
    required IconData icon,
    required Color foreground,
    Color background = Colors.white,
    double size = 108,
  }) =>
      _renderIcon(
        icon: icon,
        foreground: foreground,
        background: background,
        size: size,
      );

  static Future<BitmapDescriptor> _renderIcon({
    required IconData icon,
    required Color foreground,
    required Color background,
    required double size,
  }) async {
    if (kIsWeb) {
      return BitmapDescriptor.defaultMarker;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final dimension = size.ceil();
    final radius = dimension / 2.0;

    final backgroundPaint = Paint()
      ..color = background.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(radius, radius), radius.toDouble(), backgroundPaint);

    final borderPaint = Paint()
      ..color = foreground.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.08;
    canvas.drawCircle(
      Offset(radius, radius),
      radius - borderPaint.strokeWidth / 2,
      borderPaint,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        color: foreground,
        fontSize: size * 0.6,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
      ),
    );
    textPainter.layout();
    final iconOffset = Offset(
      radius - textPainter.width / 2,
      radius - textPainter.height / 2,
    );
    textPainter.paint(canvas, iconOffset);

    final image = await recorder.endRecording().toImage(dimension, dimension);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return BitmapDescriptor.defaultMarker;
    }
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }
}
