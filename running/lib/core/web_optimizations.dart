import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WebOptimizations {
  // Detecta plataforma
  static bool get isWeb => kIsWeb;
  
  // Configuraciones según plataforma
  static Duration get animationDuration => 
      kIsWeb ? const Duration(milliseconds: 200) : const Duration(milliseconds: 300);
      
  static Curve get animationCurve => 
      kIsWeb ? Curves.easeOut : Curves.easeInOut;
      
  static bool get useComplexAnimations => !kIsWeb;
  
  static bool get useHeavyShadows => !kIsWeb;
  
  // Optimizador de carga de datos
  static int paginationLimit(int standard) => 
      kIsWeb ? (standard ~/ 2).clamp(5, 20) : standard;
      
  // Optimizador de UI
  static EdgeInsets responsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (kIsWeb && width > 900) {
      return const EdgeInsets.all(24.0);
    } else if (kIsWeb && width > 600) {
      return const EdgeInsets.all(16.0);
    }
    return const EdgeInsets.all(12.0);
  }
  
  // Detector de rendimiento
  static bool get useWebRateLimiter => kIsWeb;
  
  // Control de debounce (actualiza solo cada X ms)
  static Duration get webThrottleDuration => 
      const Duration(milliseconds: 100);
}