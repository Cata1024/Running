import 'dart:math' as math;
import 'package:collection/collection.dart';

class TrackPoint {
  final double lat;
  final double lon;
  final double? ele;
  final DateTime timestamp;
  final double? hdop;
  final double? hr;

  const TrackPoint({
    required this.lat,
    required this.lon,
    this.ele,
    required this.timestamp,
    this.hdop,
    this.hr,
  });
}

class DerivedPoint {
  final TrackPoint point;
  final double distanceFromPrev;
  final double deltaTimeSeconds;
  final double speed;
  final double curvature;
  final double deltaEle;

  const DerivedPoint({
    required this.point,
    required this.distanceFromPrev,
    required this.deltaTimeSeconds,
    required this.speed,
    required this.curvature,
    required this.deltaEle,
  });
}

class TrackProcessingResult {
  const TrackProcessingResult({
    required this.smoothedTrack,
    required this.resampledTrack,
    required this.simplifiedTrack,
    required this.summaryPolyline,
    required this.distanceMeters,
    required this.movingTimeSeconds,
    required this.simplificationMetadata,
    this.rawTrackStoragePath,
    this.detailedTrackStoragePath,
  });

  final List<TrackPoint> smoothedTrack;
  final List<TrackPoint> resampledTrack;
  final List<TrackPoint> simplifiedTrack;
  final String summaryPolyline;
  final double distanceMeters;
  final int movingTimeSeconds;
  final Map<String, dynamic> simplificationMetadata;
  final String? rawTrackStoragePath;
  final String? detailedTrackStoragePath;

  bool get hasTrack => simplifiedTrack.length >= 2;
}

const double earthRadiusMeters = 6371000.0;

double haversineDistMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
          math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusMeters * c;
}

double _deg2rad(double deg) => deg * math.pi / 180.0;


class KalmanTrackFilter {
  KalmanTrackFilter({this.dtDefault = 1.0}) {
    state = [0, 0, 0, 0];
    covariance = List.generate(4, (_) => List.filled(4, 0.0));
    for (int i = 0; i < 4; i++) {
      covariance[i][i] = i < 2 ? 1e-6 : 1e-4;
    }
  }

  final double dtDefault;
  late List<double> state;
  late List<List<double>> covariance;

  void init(double lat, double lon) {
    state[0] = lat;
    state[1] = lon;
    state[2] = 0.0;
    state[3] = 0.0;
  }

  TrackPoint filter(
    TrackPoint point, {
    double processNoise = 1e-7,
    double measurementNoise = 1e-5,
  }) {
    final dt = dtDefault;

    final transition = [
      [1.0, 0.0, dt, 0.0],
      [0.0, 1.0, 0.0, dt],
      [0.0, 0.0, 1.0, 0.0],
      [0.0, 0.0, 0.0, 1.0],
    ];

    final predictedState = List<double>.filled(4, 0.0);
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        predictedState[i] += transition[i][j] * state[j];
      }
    }

    final process = List.generate(4, (_) => List.filled(4, 0.0));
    process[0][0] = processNoise * 1e-2;
    process[1][1] = processNoise * 1e-2;
    process[2][2] = processNoise;
    process[3][3] = processNoise;

    final predictedCovariance = List.generate(4, (_) => List.filled(4, 0.0));
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        for (int k = 0; k < 4; k++) {
          for (int l = 0; l < 4; l++) {
            predictedCovariance[i][j] +=
                transition[i][k] * covariance[k][l] * transition[j][l];
          }
        }
        predictedCovariance[i][j] += process[i][j];
      }
    }

    final measurementMatrix = [
      [1.0, 0.0, 0.0, 0.0],
      [0.0, 1.0, 0.0, 0.0],
    ];

    final hdop = point.hdop ?? 1.0;
    final measurement = [
      [measurementNoise * hdop, 0.0],
      [0.0, measurementNoise * hdop],
    ];

    final innovation = [
      [predictedCovariance[0][0] + measurement[0][0],
        predictedCovariance[0][1] + measurement[0][1]],
      [predictedCovariance[1][0] + measurement[1][0],
        predictedCovariance[1][1] + measurement[1][1]],
    ];

    final det = innovation[0][0] * innovation[1][1] -
        innovation[0][1] * innovation[1][0];
    final invInnovation = [
      [innovation[1][1] / det, -innovation[0][1] / det],
      [-innovation[1][0] / det, innovation[0][0] / det],
    ];

    final gain = List.generate(4, (_) => List.filled(2, 0.0));
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 2; j++) {
        for (int k = 0; k < 4; k++) {
          gain[i][j] += predictedCovariance[i][k] * measurementMatrix[j][k];
        }
      }
    }

    final kalman = List.generate(4, (_) => List.filled(2, 0.0));
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 2; j++) {
        for (int k = 0; k < 2; k++) {
          kalman[i][j] += gain[i][k] * invInnovation[k][j];
        }
      }
    }

    final residualLat = point.lat - predictedState[0];
    final residualLon = point.lon - predictedState[1];

    for (int i = 0; i < 4; i++) {
      state[i] = predictedState[i] +
          kalman[i][0] * residualLat +
          kalman[i][1] * residualLon;
    }

    final identityMinus = List.generate(4, (_) => List.filled(4, 0.0));
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        double value = i == j ? 1.0 : 0.0;
        for (int k = 0; k < 2; k++) {
          value -= kalman[i][k] * measurementMatrix[k][j];
        }
        identityMinus[i][j] = value;
      }
    }

    final updatedCovariance = List.generate(4, (_) => List.filled(4, 0.0));
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        for (int k = 0; k < 4; k++) {
          updatedCovariance[i][j] +=
              identityMinus[i][k] * predictedCovariance[k][j];
        }
      }
    }

    covariance = updatedCovariance;

    return TrackPoint(
      lat: state[0],
      lon: state[1],
      ele: point.ele,
      timestamp: point.timestamp,
      hdop: point.hdop,
      hr: point.hr,
    );
  }
}

List<TrackPoint> resampleByDistance(
  List<TrackPoint> points, {
  double spacingMeters = 5.0,
}) {
  if (points.isEmpty) {
    return const [];
  }
  final output = <TrackPoint>[];
  output.add(points.first);
  for (int i = 1; i < points.length; i++) {
    final previous = points[i - 1];
    final current = points[i];
    final segment =
        haversineDistMeters(previous.lat, previous.lon, current.lat, current.lon);
    if (segment == 0) {
      continue;
    }
    double ratio = spacingMeters / segment;
    double cursor = ratio;
    while (cursor <= 1.0) {
      final lat = previous.lat + (current.lat - previous.lat) * cursor;
      final lon = previous.lon + (current.lon - previous.lon) * cursor;
      final ele = _interp(previous.ele, current.ele, cursor);
      final deltaMillis =
          current.timestamp.difference(previous.timestamp).inMilliseconds;
      final timestamp = previous.timestamp.add(
        Duration(milliseconds: (deltaMillis * cursor).round()),
      );
      output.add(
        TrackPoint(lat: lat, lon: lon, ele: ele, timestamp: timestamp),
      );
      cursor += spacingMeters / segment;
    }
    output.add(current);
  }
  final filtered = <TrackPoint>[];
  TrackPoint? last;
  for (final point in output) {
    if (last == null) {
      filtered.add(point);
      last = point;
      continue;
    }
    final distance = haversineDistMeters(
      last.lat,
      last.lon,
      point.lat,
      point.lon,
    );
    if (distance >= spacingMeters * 0.1) {
      filtered.add(point);
      last = point;
    }
  }
  return filtered;
}

double? _interp(double? a, double? b, double t) {
  if (a == null || b == null) {
    return a ?? b;
  }
  return a + (b - a) * t;
}

List<DerivedPoint> deriveMetrics(List<TrackPoint> points) {
  final derived = <DerivedPoint>[];
  for (int i = 0; i < points.length; i++) {
    final current = points[i];
    double distance = 0.0;
    double deltaTime = 0.0;
    if (i > 0) {
      final previous = points[i - 1];
      distance = haversineDistMeters(
        previous.lat,
        previous.lon,
        current.lat,
        current.lon,
      );
      deltaTime =
          current.timestamp.difference(previous.timestamp).inMilliseconds /
              1000.0;
      if (deltaTime <= 0) {
        deltaTime = 1e-3;
      }
    }
    final speed = deltaTime > 0 ? distance / deltaTime : 0.0;
    double deltaEle = 0.0;
    if (i > 0 && current.ele != null && points[i - 1].ele != null) {
      deltaEle = current.ele! - points[i - 1].ele!;
    }
    double curvature = 0.0;
    if (i > 0 && i < points.length - 1) {
      final a = points[i - 1];
      final b = current;
      final c = points[i + 1];
      final v1Lat = b.lat - a.lat;
      final v1Lon = b.lon - a.lon;
      final v2Lat = c.lat - b.lat;
      final v2Lon = c.lon - b.lon;
      final dot = v1Lat * v2Lat + v1Lon * v2Lon;
      final norm1 = math.sqrt(v1Lat * v1Lat + v1Lon * v1Lon);
      final norm2 = math.sqrt(v2Lat * v2Lat + v2Lon * v2Lon);
      if (norm1 > 0 && norm2 > 0) {
        double cosAngle = dot / (norm1 * norm2);
        cosAngle = cosAngle.clamp(-1.0, 1.0);
        curvature = math.acos(cosAngle);
      }
    }
    derived.add(
      DerivedPoint(
        point: current,
        distanceFromPrev: distance,
        deltaTimeSeconds: deltaTime,
        speed: speed,
        curvature: curvature,
        deltaEle: deltaEle,
      ),
    );
  }
  return derived;
}

class _VWNode {
  _VWNode(this.index, this.area, this.previous, this.next);

  final int index;
  double area;
  int previous;
  int next;
  bool removed = false;
}

List<TrackPoint> simplifyVWWeighted(
  List<TrackPoint> points,
  List<DerivedPoint> derived, {
  double alphaCurvature = 4.0,
  double betaElevation = 1.0,
  double gammaSpeed = 1.0,
  int minimumPoints = 64,
  double keepRatio = 0.02,
}) {
  final total = points.length;
  if (total <= 3) {
    return points;
  }
  final nodes = List<_VWNode?>.filled(total, null);
  final heap = PriorityQueue<_VWNode>((a, b) => a.area.compareTo(b.area));

  double computeArea(int index) {
    final previousIndex = nodes[index]!.previous;
    final nextIndex = nodes[index]!.next;
    final a = points[previousIndex];
    final b = points[index];
    final c = points[nextIndex];
    final area = ((a.lat * b.lon + b.lat * c.lon + c.lat * a.lon) -
            (a.lon * b.lat + b.lon * c.lat + c.lon * a.lat)) /
        2.0;
    final metrics = derived[index];
    final weightCurvature = 1.0 + alphaCurvature * metrics.curvature;
    final weightElevation = 1.0 + betaElevation * metrics.deltaEle.abs();
    final weightSpeed = 1.0 + gammaSpeed * (metrics.speed.abs() / 5.0);
    final denominator =
        (weightCurvature * weightElevation * weightSpeed + 1e-12).abs();
    final value = area.abs() / denominator;
    return value;
  }

  for (int i = 0; i < total; i++) {
    final previous = i == 0 ? -1 : i - 1;
    final next = i == total - 1 ? -1 : i + 1;
    nodes[i] = _VWNode(i, double.infinity, previous, next);
  }

  for (int i = 1; i < total - 1; i++) {
    nodes[i]!.area = computeArea(i);
    heap.add(nodes[i]!);
  }

  final target = math.max(minimumPoints, (total * keepRatio).ceil());
  int remaining = total;

  while (remaining > target && heap.isNotEmpty) {
    final node = heap.removeFirst();
    if (node.removed) {
      continue;
    }
    final index = node.index;
    node.removed = true;
    nodes[index] = null;
    remaining--;

    final previous = node.previous;
    final next = node.next;

    if (previous != -1) {
      nodes[previous]!.next = next;
    }
    if (next != -1) {
      nodes[next]!.previous = previous;
    }

    if (previous > 0 && previous < total - 1 && nodes[previous] != null) {
      nodes[previous]!.area = computeArea(previous);
      heap.add(nodes[previous]!);
    }
    if (next > 0 && next < total - 1 && nodes[next] != null) {
      nodes[next]!.area = computeArea(next);
      heap.add(nodes[next]!);
    }
  }

  final result = <TrackPoint>[];
  int index = 0;
  while (index < total && nodes[index] == null) {
    index++;
  }
  while (index != -1 && index < total) {
    final node = nodes[index];
    if (node != null && !node.removed) {
      result.add(points[index]);
      index = node.next;
    } else {
      break;
    }
  }
  return result;
}

String encodePolyline(
  List<TrackPoint> points, {
  int precision = 5,
}) {
  if (points.isEmpty) {
    return '';
  }
  final factor = math.pow(10, precision).toDouble();
  int lastLat = 0;
  int lastLon = 0;
  final buffer = StringBuffer();

  for (final point in points) {
    final lat = (point.lat * factor).round();
    final lon = (point.lon * factor).round();
    final deltaLat = lat - lastLat;
    final deltaLon = lon - lastLon;
    _encodeSigned(deltaLat, buffer);
    _encodeSigned(deltaLon, buffer);
    lastLat = lat;
    lastLon = lon;
  }
  return buffer.toString();
}

void _encodeSigned(int value, StringBuffer buffer) {
  final shifted = value < 0 ? (~(value << 1)) : (value << 1);
  _encodeUnsigned(shifted, buffer);
}

void _encodeUnsigned(int value, StringBuffer buffer) {
  int temp = value;
  while (temp >= 0x20) {
    final charCode = (0x20 | (temp & 0x1f)) + 63;
    buffer.writeCharCode(charCode);
    temp >>= 5;
  }
  buffer.writeCharCode(temp + 63);
}

Future<TrackProcessingResult> processTrackPipeline(
  List<TrackPoint> rawPoints, {
  double spacingMeters = 5.0,
  double alphaCurvature = 4.0,
  double betaElevation = 1.0,
  double gammaSpeed = 1.0,
  double keepRatio = 0.02,
  int minimumPoints = 64,
  int polylinePrecision = 5,
  String simplificationMethod = 'VW_weighted',
  String simplificationVersion = 'vw-weighted-1.0',
}) async {
  final simplificationMetadata = Map<String, dynamic>.unmodifiable({
    'method': simplificationMethod,
    'params': {
      'spacing_m': spacingMeters,
      'alphaCurv': alphaCurvature,
      'betaEle': betaElevation,
      'gammaSpeed': gammaSpeed,
      'keepRatio': keepRatio,
      'minPoints': minimumPoints,
      'precision': polylinePrecision,
    },
    'version': simplificationVersion,
  });

  if (rawPoints.isEmpty) {
    return TrackProcessingResult(
      smoothedTrack: const <TrackPoint>[],
      resampledTrack: const <TrackPoint>[],
      simplifiedTrack: const <TrackPoint>[],
      summaryPolyline: '',
      distanceMeters: 0.0,
      movingTimeSeconds: 0,
      simplificationMetadata: simplificationMetadata,
    );
  }

  final filter = KalmanTrackFilter();
  filter.init(rawPoints.first.lat, rawPoints.first.lon);
  final smoothed = rawPoints.map(filter.filter).toList();

  final resampled = resampleByDistance(smoothed, spacingMeters: spacingMeters);
  final derived = deriveMetrics(resampled);

  final simplified = simplifyVWWeighted(
    resampled,
    derived,
    alphaCurvature: alphaCurvature,
    betaElevation: betaElevation,
    gammaSpeed: gammaSpeed,
    keepRatio: keepRatio,
    minimumPoints: minimumPoints,
  );

  final summary = encodePolyline(
    simplified,
    precision: polylinePrecision,
  );

  double totalDistance = 0.0;
  for (int i = 1; i < resampled.length; i++) {
    totalDistance += haversineDistMeters(
      resampled[i - 1].lat,
      resampled[i - 1].lon,
      resampled[i].lat,
      resampled[i].lon,
    );
  }

  final movingTimeSeconds = resampled.isNotEmpty
      ? resampled.last.timestamp
          .difference(resampled.first.timestamp)
          .inSeconds
      : 0;

  return TrackProcessingResult(
    smoothedTrack: List<TrackPoint>.unmodifiable(smoothed),
    resampledTrack: List<TrackPoint>.unmodifiable(resampled),
    simplifiedTrack: List<TrackPoint>.unmodifiable(simplified),
    summaryPolyline: summary,
    distanceMeters: totalDistance,
    movingTimeSeconds: movingTimeSeconds,
    simplificationMetadata: simplificationMetadata,
  );
}
