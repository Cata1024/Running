import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DynamicMap extends StatefulWidget {
  const DynamicMap({super.key});

  @override
  State<DynamicMap> createState() => _DynamicMapState();
}

class _DynamicMapState extends State<DynamicMap> {
  Set<Marker> _markers = {};
  MapIconsBundle? _icons;

  static const LatLng _startPos = LatLng(4.7110, -74.0721); // Bogotá

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    final icons = await MapIcons.load(context);
    setState(() {
      _icons = icons;
      _markers = {
        Marker(
          markerId: const MarkerId('start'),
          position: _startPos,
          icon: icons.start,
        ),
        Marker(
          markerId: const MarkerId('runner'),
          position: LatLng(_startPos.latitude + 0.002, _startPos.longitude),
          icon: icons.runner,
        ),
        Marker(
          markerId: const MarkerId('finish'),
          position: LatLng(_startPos.latitude + 0.004, _startPos.longitude),
          icon: icons.finish,
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _icons == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _startPos,
                zoom: 14,
              ),
              markers: _markers,
            ),
    );
  }
}

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
  static Future<MapIconsBundle> load([BuildContext? context]) async {
    // 🔄 Resetea el bundle si el tema cambia (por ejemplo modo oscuro)
    _bundle = null;
    _bundle ??= _createDefaultBundle(context);
    return _bundle!;
  }

  static Future<MapIconsBundle>? _bundle;

  static Future<MapIconsBundle> _createDefaultBundle(BuildContext? context) async {
    final dynamicColor = context != null
        ? Theme.of(context).colorScheme.primary
        : Colors.blueAccent;

    // 🔹 Íconos con tamaño reducido y color dinámico del tema
    final runner = await _renderIcon(
      icon: Icons.directions_run,
      color: dynamicColor,
      size: 32, // 1/4 del tamaño original
    );
    final start = await _renderIcon(
      icon: Icons.play_arrow_rounded,
      color: dynamicColor,
      size: 32,
    );
    final finish = await _renderIcon(
      icon: Icons.flag_rounded,
      color: dynamicColor,
      size: 32,
    );

    return MapIconsBundle(
      runner: runner,
      start: start,
      finish: finish,
    );
  }

  static Future<BitmapDescriptor> custom({
    required BuildContext context,
    required IconData icon,
    double size = 32,
  }) {
    final color = Theme.of(context).colorScheme.primary;
    return _renderIcon(icon: icon, color: color, size: size);
  }

  static Future<BitmapDescriptor> _renderIcon({
    required IconData icon,
    required Color color,
    double size = 32,
  }) async {
    if (kIsWeb) return BitmapDescriptor.defaultMarker;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final dim = size.ceil().toDouble();

    // 🧩 Dibuja solo el ícono, sin fondo
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        color: color,
        fontSize: size,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        shadows: const [
          Shadow(
            blurRadius: 2,
            color: Colors.black26,
            offset: Offset(0.5, 0.5),
          ),
        ],
      ),
    );
    textPainter.layout();

    final offset = Offset(
      (dim - textPainter.width) / 2,
      (dim - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);

    final image = await recorder.endRecording().toImage(dim.toInt(), dim.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }
}
