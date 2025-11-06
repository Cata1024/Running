import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';

/// Optimizaciones de Riverpod con .select() para reducir rebuilds

/// En lugar de observar el perfil completo con:
/// final profile = ref.watch(userProfileDtoProvider);
/// 
/// Usa .select() cuando solo necesitas un campo específico:
/// final displayName = ref.watch(
///   userProfileDtoProvider.select((async) => async.maybeWhen(
///     data: (dto) => dto?.displayName,
///     orElse: () => null,
///   ))
/// );

/// Provider optimizado para solo escuchar el displayName
final userDisplayNameProvider = Provider<String?>((ref) {
  return ref.watch(userProfileDtoProvider.select((async) => async.maybeWhen(
        data: (dto) => dto?.displayName,
        orElse: () => null,
      )));
});

/// Provider optimizado para solo escuchar el nivel del usuario
final userLevelProvider = Provider<int>((ref) {
  return ref.watch(userProfileDtoProvider.select((async) => async.maybeWhen(
        data: (dto) => dto?.level ?? 1,
        orElse: () => 1,
      )));
});

/// Provider optimizado para solo escuchar el total de runs
final userTotalRunsProvider = Provider<int>((ref) {
  return ref.watch(userProfileDtoProvider.select((async) => async.maybeWhen(
        data: (dto) => dto?.totalRuns ?? 0,
        orElse: () => 0,
      )));
});

/// Provider optimizado para el conteo de runs (sin rebuild cuando cambia la lista completa)
final userRunsCountProvider = Provider<int>((ref) {
  return ref.watch(userRunsDtoProvider.select((async) => async.maybeWhen(
        data: (runs) => runs.length,
        orElse: () => 0,
      )));
});

final userPhotoUrlProvider = Provider<String?>((ref) {
  return ref.watch(userProfileDtoProvider.select((async) => async.maybeWhen(
        data: (dto) => dto?.photoUrl,
        orElse: () => null,
      )));
});

final userLastActivityProvider = Provider<DateTime?>((ref) {
  return ref.watch(userProfileDtoProvider.select((async) => async.maybeWhen(
        data: (dto) => dto?.lastActivityAt,
        orElse: () => null,
      )));
});

final userTotalDistanceProvider = Provider<double?>((ref) {
  return ref.watch(userProfileDtoProvider.select((async) => async.maybeWhen(
        data: (dto) => dto?.totalDistance,
        orElse: () => null,
      )));
});

final userTotalTimeProvider = Provider<int?>((ref) {
  return ref.watch(userProfileDtoProvider.select((async) => async.maybeWhen(
        data: (dto) => dto?.totalTime,
        orElse: () => null,
      )));
});

final userExperienceProvider = Provider<int?>((ref) {
  return ref.watch(userProfileDtoProvider.select((async) => async.maybeWhen(
        data: (dto) => dto?.experience,
        orElse: () => null,
      )));
});

/// Ejemplo de uso en un widget:
/// 
/// En lugar de:
/// ```dart
/// final runsAsync = ref.watch(userRunsDtoProvider);
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
///   final profile = ref.watch(userProfileDtoProvider);
///   final level = profile.maybeWhen(data: (d) => d?.level ?? 1, orElse: () => 1);
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
///     userProfileDtoProvider.select((async) => 
///       async.maybeWhen(
///         data: (dto) => dto?.level ?? 1,
///         orElse: () => 1,
///       )
///     )
///   );
///   return Text('Level: $level');
/// }
/// ```
