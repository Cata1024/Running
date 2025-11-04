/// Barrel file para todos los widgets Aero
/// 
/// Importa todos los componentes del sistema de diseño Aero
/// en un solo lugar para facilitar su uso.
/// 
/// Uso:
/// ```dart
/// import 'package:running/core/widgets/aero_widgets.dart';
/// 
/// // Ahora tienes acceso a todos los componentes Aero
/// AeroButton(...)
/// AeroCard(...)
/// AeroDialog.show(...)
/// ```
library;

// Componentes base
export 'aero_surface.dart';
export 'aero_button.dart'; // Incluye AeroIconButton y AeroFab

// Formularios
export 'aero_text_field.dart';
export 'aero_dropdown.dart';

// Navegación
export 'aero_nav_bar.dart';

// Listas
export 'aero_list_tile.dart';

// Contenedores y cards
export 'aero_card.dart';

// Diálogos y overlays
export 'aero_dialog.dart';
export 'aero_bottom_sheet.dart';

// Chips y badges
export 'aero_chip.dart';
export 'aero_badge.dart';

// Estados
export 'loading_state.dart';
export 'error_state.dart';
export 'empty_state.dart';

// Otros
export 'stat_card.dart';
export 'mini_map.dart';
