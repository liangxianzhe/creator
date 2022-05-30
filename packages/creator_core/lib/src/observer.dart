import 'core.dart';

/// Observer can listen to creator state changes.
class CreatorObserver {
  const CreatorObserver();
  void onStateChange(CreatorBase creator, Object? before, Object? after) {}
  void onError(CreatorBase creator, Object? error) {}
}

/// Default observer which just log the new states.
class DefaultCreatorObserver extends CreatorObserver {
  const DefaultCreatorObserver();

  @override
  void onStateChange(CreatorBase creator, Object? before, Object? after) {
    if (ignore(creator)) {
      return;
    }
    print('[Creator] ${creator.infoName}: $after');
  }

  @override
  void onError(CreatorBase creator, Object? error) {
    if (ignore(creator)) {
      return;
    }
    print('[Creator][Error] ${creator.infoName}: $error');
  }

  /// Ignore a few derived creators to reduce log amount.
  bool ignore(CreatorBase creator) {
    return (creator.name?.endsWith('_asyncData') ?? false) ||
        (creator.name?.endsWith('_change') ?? false);
  }
}
