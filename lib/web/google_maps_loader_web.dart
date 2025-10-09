// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

Completer<void>? _mapsLoader;

Future<void> initializeGoogleMaps(String apiKey) {
  if (_mapsLoader != null) {
    return _mapsLoader!.future;
  }

  final completer = Completer<void>();

  final existing =
      html.document.head?.querySelector('script[data-google-maps]');
  if (existing != null) {
    completer.complete();
    _mapsLoader = completer;
    return completer.future;
  }

  final script = html.ScriptElement()
    ..type = 'text/javascript'
    ..async = true
    ..defer = true
    ..dataset['googleMaps'] = 'true'
    ..src =
        'https://maps.googleapis.com/maps/api/js?key=$apiKey&libraries=places';

  script.onError.listen((event) {
    if (!completer.isCompleted) {
      completer.completeError(StateError('Failed to load Google Maps script'));
    }
  });

  script.onLoad.listen((event) {
    if (!completer.isCompleted) {
      completer.complete();
    }
  });

  html.document.head?.append(script);

  _mapsLoader = completer;
  return completer.future;
}
