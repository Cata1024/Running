import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debouncer para reducir llamadas repetitivas
/// 
/// Uso:
/// ```dart
/// final debouncer = Debouncer(milliseconds: 300);
/// 
/// TextField(
///   onChanged: (value) {
///     debouncer.run(() => performSearch(value));
///   },
/// )
/// ```
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  /// Ejecutar callback después del delay
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Cancelar timer pendiente
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose del debouncer
  void dispose() {
    _timer?.cancel();
  }
}

/// Debouncer con soporte para async
class AsyncDebouncer {
  final int milliseconds;
  Timer? _timer;

  AsyncDebouncer({required this.milliseconds});

  /// Ejecutar callback async después del delay
  void run(Future<void> Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), () async {
      await action();
    });
  }

  /// Cancelar timer pendiente
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose del debouncer
  void dispose() {
    _timer?.cancel();
  }
}

/// Extension para agregar debounce a ValueNotifier
extension DebouncedValueNotifier<T> on ValueNotifier<T> {
  /// Crear un ValueNotifier debounced
  ValueNotifier<T> debounce({int milliseconds = 300}) {
    final debounced = ValueNotifier<T>(value);
    Timer? timer;

    addListener(() {
      timer?.cancel();
      timer = Timer(Duration(milliseconds: milliseconds), () {
        debounced.value = value;
      });
    });

    return debounced;
  }
}

/// Throttler para limitar la frecuencia de ejecución
/// 
/// Uso:
/// ```dart
/// final throttler = Throttler(milliseconds: 1000);
/// 
/// onScroll: () {
///   throttler.run(() => loadMoreData());
/// }
/// ```
class Throttler {
  final int milliseconds;
  Timer? _timer;
  bool _isThrottled = false;

  Throttler({required this.milliseconds});

  /// Ejecutar callback si no está throttled
  void run(VoidCallback action) {
    if (_isThrottled) return;

    action();
    _isThrottled = true;

    _timer = Timer(Duration(milliseconds: milliseconds), () {
      _isThrottled = false;
    });
  }

  /// Cancelar throttle
  void cancel() {
    _timer?.cancel();
    _isThrottled = false;
  }

  /// Dispose del throttler
  void dispose() {
    _timer?.cancel();
  }
}
