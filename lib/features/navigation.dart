import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider global para controlar el índice de la barra de navegación inferior.
final navIndexProvider = StateProvider<int>((ref) => 0);
