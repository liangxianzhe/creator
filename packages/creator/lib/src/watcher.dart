import 'package:creator/creator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Watch creators to build a widget or to perform other action.
class Watcher extends StatefulWidget {
  const Watcher(this.builder,
      {Key? key,
      this.listener,
      this.builderName,
      this.listenerName,
      this.child})
      : assert(!(builder == null && child == null),
            'builder and child cannot both be null'),
        super(key: key);

  /// Allows watching creators to populate a widget.
  final Widget Function(BuildContext context, Ref ref, Widget? child)? builder;

  /// Allows watching creators to perform action. It is independent to builder.
  final void Function(Ref ref)? listener;

  /// Optional name for the builder creator.
  final String? builderName;

  /// Optional name for the listener creator.
  final String? listenerName;

  /// If set, it is passed into builder. Can be used if the subtree should not
  /// rebuild when dependency state changes.
  final Widget? child;

  @override
  State<Watcher> createState() => _WatcherState();
}

class _WatcherState extends State<Watcher> {
  Creator<void>? builder;
  Creator<void>? listener;
  late Ref ref;

  /// Whether build() is in progress. This allows builder to differentiate
  /// create call triggered by Flutter vs triggered by dependency state change.
  bool building = false;

  /// Set when dependency changes. Cleared by next build call. This avoids
  /// calling builder function twice.
  bool dependencyChanged = false;

  bool built = false;
  late Widget last;

  void _setup() {
    if (widget.builder != null) {
      builder = Creator((ref) {
        if (!building) {
          setState(() {});
          // Tell the framework that this rebuild didn't change dependency, even though we didn't
          // call any watch function.
          ref.keepDependency();
        } else {
          last = widget.builder!(context, ref, widget.child);
        }
      }, name: widget.builderName ?? 'watcher');
      // Not watch(builder) here, use recreate(builder) later.
    }
    if (widget.listener != null) {
      listener =
          Creator(widget.listener!, name: widget.listenerName ?? 'listener');
      ref.watch(listener!);
    }
  }

  void _dispose() {
    if (builder != null) {
      ref.dispose(builder!);
    }
    if (listener != null) {
      ref.dispose(listener!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref = CreatorGraphData.of(context).ref; // Save ref to use in dispose.
    _dispose();
    _setup();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (builder == null) {
      return widget.child!;
    }
    building = true;
    ref.recreate(builder!); // Recreate will add builder to the graph.
    building = false;
    return last;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // For now, we just dump the whole graph to DevTools.
    properties.add(StringProperty('graph', ref.graphString(),
        level: DiagnosticLevel.debug));
  }
}
