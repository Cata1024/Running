import 'package:flutter/material.dart';

import '../../core/map_styles.dart';
import '../providers/app_providers.dart';

String? resolveMapStyle(MapVisualStyle preference, Brightness brightness) {
  switch (preference) {
    case MapVisualStyle.automatic:
      return brightness == Brightness.dark ? MapStyles.dark : MapStyles.light;
    case MapVisualStyle.light:
      return MapStyles.light;
    case MapVisualStyle.dark:
      return MapStyles.dark;
    case MapVisualStyle.off:
      return null;
  }
}
