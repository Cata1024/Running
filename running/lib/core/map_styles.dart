/// Estilos de Google Maps en formato JSON para un look más limpio y acorde a M3
class MapStyles {
  static const String light = '''[
    {"featureType":"poi","stylers":[{"visibility":"off"}]},
    {"featureType":"transit","stylers":[{"visibility":"off"}]},
    {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"saturation":-20},{"lightness":10}]},
    {"featureType":"water","stylers":[{"color":"#cbe7ff"}]},
    {"featureType":"landscape","stylers":[{"color":"#f2f4f7"}]}
  ]''';

  static const String dark = '''[
    {"elementType":"geometry","stylers":[{"color":"#1f1f1f"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#a7a7a7"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#1f1f1f"}]},
    {"featureType":"poi","stylers":[{"visibility":"off"}]},
    {"featureType":"transit","stylers":[{"visibility":"off"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2a2a2a"}]},
    {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"featureType":"water","stylers":[{"color":"#0e3a5a"}]}
  ]''';
}
