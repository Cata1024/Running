import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';

/// Optimizaciones de Riverpod con .select() para reducir rebuilds

/// En lugar de:
/// final profile = ref.watch(userProfileDocProvider);
/// 
/// Usa .select() cuando solo necesitas un campo específico:
/// final displayName = ref.watch(
///   userProfileDocProvider.select((profile) => profile.value?['displayName'])
/// );

/// Provider optimizado para solo escuchar el displayName
final userDisplayNameProvider = Provider<String?>((ref) {
  final profileAsync = ref.watch(userProfileDocProvider);
  return profileAsync.maybeWhen(
    data: (data) => data?['displayName'] as String?,
    orElse: () => null,
  );
});

/// Provider optimizado para solo escuchar el nivel del usuario
final userLevelProvider = Provider<int>((ref) {
  final profileAsync = ref.watch(userProfileDocProvider);
  return profileAsync.maybeWhen(
    data: (data) => (data?['level'] as num?)?.toInt() ?? 1,
    orElse: () => 1,
  );
});

/// Provider optimizado para solo escuchar el total de runs
final userTotalRunsProvider = Provider<int>((ref) {
  final profileAsync = ref.watch(userProfileDocProvider);
  return profileAsync.maybeWhen(
    data: (data) => (data?['totalRuns'] as num?)?.toInt() ?? 0,
    orElse: () => 0,
  );
});

/// Provider optimizado para el conteo de runs (sin rebuild cuando cambia la lista completa)
final userRunsCountProvider = Provider<int>((ref) {
  final runsAsync = ref.watch(userRunsProvider);
  return runsAsync.maybeWhen(
    data: (runs) => runs.length,
    orElse: () => 0,
  );
});

/// Ejemplo de uso en un widget:
/// 
/// En lugar de:
/// ```dart
/// final runsAsync = ref.watch(userRunsProvider);
/// final runCount = runsAsync.maybeWhen(
///   data: (runs) => runs.length,
///   orElse: () => 0,
/// );
/// ```
/// 
/// Usa:
/// ```dart
/// final runCount = ref.watch(userRunsCountProvider);
/// ```
/// 
/// Esto evita rebuilds cuando la lista de runs cambia pero el conteo no.

/// GUÍA DE OPTIMIZACIÓN:
/// 
/// 1. Identifica qué partes del estado realmente necesita tu widget
/// 2. Usa .select() para extraer solo esos datos
/// 3. Crea providers derivados para cálculos complejos
/// 4. Evita ref.watch() en providers pesados si solo necesitas un campo
/// 
/// EJEMPLO PRÁCTICO:
/// 
/// ❌ MAL - Rebuilds cada vez que cualquier cosa cambia en el profile:
/// ```dart
/// Widget build(BuildContext context, WidgetRef ref) {
///   final profile = ref.watch(userProfileDocProvider);
///   final level = profile.value?['level'] ?? 1;
///   return Text('Level: $level');
/// }
/// ```
/// 
/// ✅ BIEN - Solo rebuilds cuando el nivel cambia:
/// ```dart
/// Widget build(BuildContext context, WidgetRef ref) {
///   final level = ref.watch(userLevelProvider);
///   return Text('Level: $level');
/// }
/// ```
/// 
/// ✅ MEJOR - Usando .select() directamente:
/// ```dart
/// Widget build(BuildContext context, WidgetRef ref) {
///   final level = ref.watch(
///     userProfileDocProvider.select((async) => 
///       async.maybeWhen(
///         data: (data) => (data?['level'] as num?)?.toInt() ?? 1,
///         orElse: () => 1,
///       )
///     )
///   );
///   return Text('Level: $level');
/// }
/// ```
