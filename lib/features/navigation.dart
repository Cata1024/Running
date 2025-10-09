import 'package:flutter_riverpod/legacy.dart';

/// Provider global para controlar el índice de la barra de navegación inferior.
final navIndexProvider = StateProvider<int>((ref) => 0);
