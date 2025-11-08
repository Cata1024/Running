import '../entities/run.dart';

/// Contract to interact with persistent run data without leaking
/// infrastructure details into the domain layer.
abstract class IRunRepository {
  Future<String> createRun(Map<String, dynamic> payload);

  Future<Run?> fetchRun(String id);

  Future<List<Run>> fetchRuns({int limit = 20});

  Future<void> updateRun(String id, Map<String, dynamic> payload);

  Future<void> deleteRun(String id);
}
