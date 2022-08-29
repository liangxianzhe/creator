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
  Creator<Widget>? builder;
  Creator<void>? listener;
  late Ref ref;

  /// Whether build() is in progress. This allows builder to differentiate
  /// create call triggered by Flutter vs triggered by dependency state change.
  bool building = false;

  /// Set when dependency changes. Cleared by next build call. This avoids
  /// calling builder function twice.
  bool dependencyChanged = false;

  void _setup() {
    if (widget.builder != null) {
      builder = Creator((ref) {
        if (!building) {
          // Dependency state changes. Set dependencyChanged so that next time
          // build is called, we skip recreating the creator. This way the
          // builder function is only called once.
          setState(() {
            dependencyChanged = true;
          });
        }
        return widget.builder!(context, ref, widget.child);
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
    // Recreate will add builder to the graph. Recreate its state if the build
    // call is triggered by Flutter rather than dependency change.
    if (!dependencyChanged) {
      ref.recreate(builder!);
    }
    building = false;
    dependencyChanged = false;
    return ref.read(builder!);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // For now, we just dump the whole graph to DevTools.
    properties.add(StringProperty('graph', ref.graphString(),
        level: DiagnosticLevel.debug));
  }
}
