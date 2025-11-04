import 'package:flutter/material.dart';

/// Logo de Google usando SVG paths
/// No requiere asset externo
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({
    super.key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Blue
    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.533, size.height * 0.5)
        ..lineTo(size.width * 0.967, size.height * 0.5)
        ..cubicTo(
          size.width * 0.967,
          size.height * 0.733,
          size.width * 0.767,
          size.height * 0.933,
          size.width * 0.533,
          size.height * 0.933,
        )
        ..cubicTo(
          size.width * 0.3,
          size.height * 0.933,
          size.width * 0.1,
          size.height * 0.733,
          size.width * 0.1,
          size.height * 0.5,
        )
        ..cubicTo(
          size.width * 0.1,
          size.height * 0.267,
          size.width * 0.3,
          size.height * 0.067,
          size.width * 0.533,
          size.height * 0.067,
        )
        ..cubicTo(
          size.width * 0.633,
          size.height * 0.067,
          size.width * 0.717,
          size.height * 0.1,
          size.width * 0.783,
          size.height * 0.15,
        )
        ..lineTo(size.width * 0.9, size.height * 0.033)
        ..cubicTo(
          size.width * 0.8,
          size.height * -0.033,
          size.width * 0.683,
          size.height * -0.067,
          size.width * 0.533,
          size.height * -0.067,
        ),
      paint,
    );

    // Red
    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.533, size.height * 0.067)
        ..lineTo(size.width * 0.783, size.height * 0.15)
        ..lineTo(size.width * 0.9, size.height * 0.033)
        ..cubicTo(
          size.width * 1.0,
          size.height * 0.133,
          size.width * 1.033,
          size.height * 0.25,
          size.width * 1.033,
          size.height * 0.367,
        )
        ..lineTo(size.width * 0.967, size.height * 0.5)
        ..lineTo(size.width * 0.533, size.height * 0.5)
        ..close(),
      paint,
    );

    // Yellow
    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.1, size.height * 0.5)
        ..cubicTo(
          size.width * 0.1,
          size.height * 0.733,
          size.width * 0.3,
          size.height * 0.933,
          size.width * 0.533,
          size.height * 0.933,
        )
        ..lineTo(size.width * 0.667, size.height * 0.8)
        ..cubicTo(
          size.width * 0.583,
          size.height * 0.867,
          size.width * 0.483,
          size.height * 0.9,
          size.width * 0.367,
          size.height * 0.9,
        )
        ..cubicTo(
          size.width * 0.183,
          size.height * 0.9,
          size.width * 0.033,
          size.height * 0.75,
          size.width * 0.033,
          size.height * 0.567,
        )
        ..close(),
      paint,
    );

    // Green
    paint.color = const Color(0xFF34A853);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.533, size.height * 0.933)
        ..cubicTo(
          size.width * 0.767,
          size.height * 0.933,
          size.width * 0.967,
          size.height * 0.733,
          size.width * 0.967,
          size.height * 0.5,
        )
        ..lineTo(size.width * 0.667, size.height * 0.8)
        ..cubicTo(
          size.width * 0.583,
          size.height * 0.867,
          size.width * 0.483,
          size.height * 0.9,
          size.width * 0.367,
          size.height * 0.9,
        )
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
