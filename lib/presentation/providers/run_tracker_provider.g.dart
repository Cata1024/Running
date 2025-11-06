// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_tracker_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RunTracker)
const runTrackerProvider = RunTrackerProvider._();

final class RunTrackerProvider extends $NotifierProvider<RunTracker, RunState> {
  const RunTrackerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'runTrackerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$runTrackerHash();

  @$internal
  @override
  RunTracker create() => RunTracker();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RunState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RunState>(value),
    );
  }
}

String _$runTrackerHash() => r'96ce29166610efb433ac048b966cb189034fc20b';

abstract class _$RunTracker extends $Notifier<RunState> {
  RunState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<RunState, RunState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<RunState, RunState>, RunState, Object?, Object?>;
    element.handleValue(ref, created);
  }
}
