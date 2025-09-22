import 'package:latlong2/latlong.dart';

/// Utilidades comunes para Territory Run
class AppUtils {
  
  /// Calcular distancia entre dos puntos en metros usando la fórmula de Haversine
  static double calculateDistance(LatLng point1, LatLng point2) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }
  
  /// Calcular velocidad en m/s dados distancia (metros) y tiempo (segundos)
  static double calculateSpeed(double distanceMeters, int timeSeconds) {
    if (timeSeconds <= 0) return 0.0;
    return distanceMeters / timeSeconds;
  }
  
  /// Calcular ritmo en segundos por kilómetro
  static int calculatePaceSecondsPerKm(double speedMs) {
    if (speedMs <= 0) return 0;
    return (1000 / speedMs).round();
  }
  
  /// Formatear tiempo en formato HH:MM:SS
  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
             '${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }
  
  /// Formatear distancia (metros a km con decimales)
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }
  
  /// Formatear ritmo (segundos por km a MM:SS)
  static String formatPace(int secondsPerKm) {
    if (secondsPerKm <= 0) return '--:--';
    final minutes = secondsPerKm ~/ 60;
    final seconds = secondsPerKm % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }
  
  /// Calcular área de un polígono usando la fórmula del área de un polígono
  static double calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    double area = 0.0;
    final n = points.length;
    
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    
    area = area.abs() / 2.0;
    
    // Convertir de grados cuadrados a metros cuadrados (aproximación)
    const double degreesToMeters = 111320.0; // metros por grado en el ecuador
    return area * degreesToMeters * degreesToMeters;
  }
  
  /// Simplificar una ruta usando el algoritmo Douglas-Peucker
  static List<LatLng> simplifyRoute(List<LatLng> points, double epsilon) {
    if (points.length < 3) return points;
    
    return _douglasPeucker(points, epsilon);
  }
  
  /// Implementación del algoritmo Douglas-Peucker
  static List<LatLng> _douglasPeucker(List<LatLng> points, double epsilon) {
    if (points.length < 3) return points;
    
    // Encontrar el punto con la distancia perpendicular máxima
    double maxDistance = 0;
    int maxIndex = 0;
    final start = points.first;
    final end = points.last;
    
    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(points[i], start, end);
      if (distance > maxDistance) {
        maxIndex = i;
        maxDistance = distance;
      }
    }
    
    // Si la distancia máxima es mayor que epsilon, dividir recursivamente
    if (maxDistance > epsilon) {
      final firstHalf = _douglasPeucker(
        points.sublist(0, maxIndex + 1), 
        epsilon
      );
      final secondHalf = _douglasPeucker(
        points.sublist(maxIndex), 
        epsilon
      );
      
      // Combinar resultados eliminando el punto duplicado
      return [...firstHalf.sublist(0, firstHalf.length - 1), ...secondHalf];
    } else {
      // Si todos los puntos están dentro de epsilon, devolver solo start y end
      return [start, end];
    }
  }
  
  /// Calcular distancia perpendicular de un punto a una línea
  static double _perpendicularDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    // Usar fórmula de distancia punto-línea aproximada para coordenadas geográficas
    final A = point.latitude - lineStart.latitude;
    final B = point.longitude - lineStart.longitude;
    final C = lineEnd.latitude - lineStart.latitude;
    final D = lineEnd.longitude - lineStart.longitude;
    
    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    
    if (lenSq == 0) {
      return calculateDistance(point, lineStart);
    }
    
    final param = dot / lenSq;
    LatLng closestPoint;
    
    if (param < 0) {
      closestPoint = lineStart;
    } else if (param > 1) {
      closestPoint = lineEnd;
    } else {
      closestPoint = LatLng(
        lineStart.latitude + param * C,
        lineStart.longitude + param * D,
      );
    }
    
    return calculateDistance(point, closestPoint);
  }
  
  /// Validar si un punto GPS es válido
  static bool isValidGpsPoint(LatLng point) {
    return point.latitude >= -90 && 
           point.latitude <= 90 &&
           point.longitude >= -180 && 
           point.longitude <= 180;
  }
  
  /// Detectar si hay un "teleport" sospechoso en la velocidad
  static bool detectTeleport(LatLng from, LatLng to, int timeMs) {
    if (timeMs <= 0) return false;
    
    final distance = calculateDistance(from, to);
    final speedMs = distance / (timeMs / 1000.0);
    
    // Si la velocidad supera los 20 m/s (72 km/h), es sospechoso
    return speedMs > 20.0;
  }
}