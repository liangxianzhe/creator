import 'package:creator/creator.dart';
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

/// Default observer which just log the new states.
class DefaultCreatorObserver extends CreatorObserver {
  const DefaultCreatorObserver();

  @override
  void onStateChange(CreatorBase creator, Object? before, Object? after) {
    if (ignore(creator)) {
      return;
    }
    debugPrint('[Creator] ${creator.infoName}: $after');
  }

  @override
  void onError(CreatorBase creator, Object? error, StackTrace? stackTrace) {
    if (ignore(creator)) {
      return;
    }
    debugPrint('[Creator][Error] ${creator.infoName}: $error\n$stackTrace');
  }

  /// Ignore a few derived creators to reduce log amount.
  bool ignore(CreatorBase creator) {
    return (creator.name == 'watcher' ||
        creator.name == 'listener' ||
        (creator.name?.endsWith('_asyncData') ?? false) ||
        (creator.name?.endsWith('_change') ?? false));
  }
}
