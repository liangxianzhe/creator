import 'package:creator/creator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// CreatorGraph holds a Ref, which holds the graph internally. Flutter app
/// should be wrapped with this. By default it uses [DefaultCreatorObserver] to
/// log state changes.
class CreatorGraph extends StatefulWidget {
  CreatorGraph({
    Key? key,
    CreatorObserver observer = const DefaultCreatorObserver(),
    required this.child,
  })  : ref = Ref(observer: observer),
        super(key: key);

  final Ref ref;
  final Widget child;

  @override
  State<CreatorGraph> createState() => _CreatorGraph();
}

class _CreatorGraph extends State<CreatorGraph> {
  @override
  void dispose() {
    widget.ref.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CreatorGraphData(ref: widget.ref, child: widget.child);
  }
}

/// The inherit widget for CreatorGraph.
class CreatorGraphData extends InheritedWidget {
  const CreatorGraphData({
    Key? key,
    required this.ref,
    required Widget child,
  }) : super(key: key, child: child);

  final Ref ref;

  static CreatorGraphData of(BuildContext context) {
    final CreatorGraphData? result =
        context.dependOnInheritedWidgetOfExactType<CreatorGraphData>();
    return result!;
  }

  @override
  bool updateShouldNotify(CreatorGraphData oldWidget) => ref != oldWidget.ref;
}

extension ContextRef on BuildContext {
  Ref get ref => CreatorGraphData.of(this).ref;
}

/// Default observer which just log the new states and error.
class DefaultCreatorObserver extends CreatorObserver {
  const DefaultCreatorObserver({
    this.logInReleaseMode = false,
    this.logStateChange = true,
    this.logState = true,
    this.logError = true,
    this.logDispose = false,
    this.logWatcher = false,
    this.logDerived = false,
  });

  /// Whether to log in release mode. Default to false.
  final bool logInReleaseMode;

  /// Whether to log state change events. Default to true.
  final bool logStateChange;

  /// Whether to log the state object when state changes. Default to true.
  final bool logState;

  /// Whether to log error events. Default to true.
  final bool logError;

  /// Whether to log dispose events. Default to false.
  final bool logDispose;

  /// Whether to log [Watcher] that has a default name. Default to false to
  /// reduce log amount.
  final bool logWatcher;

  /// Whether to log derived creators (.asyncData, .change). Default to false to
  /// reduce log amount.
  final bool logDerived;

  @override
  void onStateChange(CreatorBase creator, Object? before, Object? after) {
    if (!kDebugMode && !logInReleaseMode) {
      return;
    }
    if (!logStateChange || ignore(creator)) {
      return;
    }
    if (logState) {
      debugPrint('[Creator] ${creator.infoName}: $after');
    } else {
      debugPrint('[Creator][Change] ${creator.infoName}');
    }
  }

  @override
  void onError(CreatorBase creator, Object? error, StackTrace? stackTrace) {
    if (!kDebugMode && !logInReleaseMode) {
      return;
    }
    if (!logError || ignore(creator)) {
      return;
    }
    debugPrint('[Creator][Error] ${creator.infoName}: $error\n$stackTrace');
  }

  @override
  void onDispose(CreatorBase creator) {
    if (!kDebugMode && !logInReleaseMode) {
      return;
    }
    if (!logDispose || ignore(creator)) {
      return;
    }
    debugPrint('[Creator][Dispose] ${creator.infoName}');
  }

  /// Ignore a few derived creators to reduce log amount.
  bool ignore(CreatorBase creator) {
    if (creator.name == 'watcher' || creator.name == 'listener') {
      return !logWatcher;
    } else if ((creator.name?.endsWith('_asyncData') ?? false) ||
        (creator.name?.endsWith('_change') ?? false)) {
      return !logDerived;
    }
    return false;
  }
}
