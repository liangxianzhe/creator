part of 'core.dart';

/// Ref holds the creator graph data, including states and dependencies.
class Ref {
  Ref._({
    CreatorBase? owner,
    CreatorObserver? observer,
    Map<CreatorBase, ElementBase>? elements,
    Graph<CreatorBase>? graph,
    Map<CreatorBase, Set<CreatorBase>>? before,
    Map<CreatorBase, Set<CreatorBase>>? after,
    Set<CreatorBase>? toCreate,
    final Map<CreatorBase, void Function()>? onClean,
  })  : _owner = owner,
        _observer = observer,
        _elements = elements ?? {},
        _graph = graph ??
            Graph(name: (c) => c.infoName, keepAlive: (c) => c.keepAlive),
        _before = before ?? {},
        _after = after ?? {},
        _toCreate = toCreate ?? {},
        _clean = onClean ?? {};

  Ref({CreatorObserver? observer}) : this._(observer: observer);

  /// Create a lightweight copy of Ref with a owner. The copy points to
  /// the same internal graph. See [_owner].
  Ref _copy(CreatorBase owner) {
    return Ref._(
      owner: owner,
      observer: _observer,
      elements: _elements,
      graph: _graph,
      before: _before,
      after: _after,
      toCreate: _toCreate,
      onClean: _clean,
    );
  }

  /// Owner of this Ref. It is used to establish the dependency when [watch].
  ///
  /// ```dart
  /// Ref ref;  // ref._owner is null
  /// final secondCreator = Creator((ref) {  // ref._owner is secondCreator
  ///   // When this watch is called, we can establish the dependency of
  ///   // firstCreator -> ref._owner (secondCreator).
  ///   final first = ref.watch(firstCreator);
  ///   return first * 2;
  /// });
  /// ```
  final CreatorBase? _owner;

  /// Observer is called when state changes.
  final CreatorObserver? _observer;

  /// Elements which hold state.
  final Map<CreatorBase, ElementBase> _elements;

  /// Dependency graph. Think this as a directional graph.  A -> [B, C] means if
  /// A changes, B and C need change too.
  final Graph<CreatorBase> _graph;

  /// Map of <creator being recreated, its dependency before recreating>.
  /// It is needed to allow dynamic dependencies.
  ///
  /// ```dart
  /// final C = Creator((ref) {
  ///   final value = ref.watch(A);
  ///   return value >= 0 ? value : ref.watch(B);
  /// });
  /// ```
  ///
  /// In this example, A -> C always exists, B -> C may or may not exist.
  ///
  /// Before we recreate C, we keep a copy of its old dependencies in [_before].
  /// During recreation we record new dependencies in [_after]. Then we compare
  /// them once recreation is finished.
  ///
  /// Recreation might take a while if it is waiting for async task. While it is
  /// waiting, its dependency might changes and trigger a second recreation job.
  /// If this happens, we will simply add the creator to [_toCreate]. Later we
  /// can start the second job when first job is finished.
  final Map<CreatorBase, Set<CreatorBase>> _before;

  /// See [_before].
  final Map<CreatorBase, Set<CreatorBase>> _after;

  /// See [_before].
  final Set<CreatorBase> _toCreate;

  /// User provided call back function, which should be called before next
  /// recreate call or after creator is disposed.
  final Map<CreatorBase, void Function()> _clean;

  /// Get or create an element for creator. We call [ElementBase.recreate]
  /// following create the element, unless [recreate] is set to false.
  /// [autoDispose] makes creator remove itself from the graph after creating
  /// element and getting state.
  ElementBase<T> _element<T>(CreatorBase<T> creator,
      {bool recreate = true, bool autoDispose = false}) {
    if (_elements.containsKey(creator)) {
      return _elements[creator]! as ElementBase<T>;
    }
    // Note _copy is called here to get a copy of Ref.
    final element = creator._createElement(_copy(creator));
    _elements[creator] = element;
    if (recreate) {
      element.recreate(autoDispose: autoDispose);
    }
    return element;
  }

  /// Read the current state of the creator.
  /// - If creator is already in the graph, its value is returned.
  /// - If creator is not in the graph, it is added to the graph then removed.
  T read<T>(CreatorBase<T> creator) {
    return _element<T>(creator, autoDispose: true).getState();
  }

  /// Read the current state of the ref owner. This allows creators to have
  /// memories. Note that the creator needs defined in a stable variable or use
  /// args if using this method. See [CreatorBase.args].
  T? readSelf<T>() {
    assert(_owner != null, 'readSelf is called outside of create method');
    if (!_elements.containsKey(_owner)) {
      return null;
    }
    return _owner is Creator<T>
        ? _element(_owner! as Creator<T>).state
        : (_element(_owner! as Emitter<T>) as EmitterElement<T>).value;
  }

  /// Read the current state of the creator, also establish the dependency
  /// [creator] -> [_owner].
  T watch<T>(CreatorBase<T> creator) {
    if (_owner != null) {
      _graph.addEdge(creator, _owner!);
      _after[_owner!]?.add(creator);
    }
    return _element<T>(creator).getState();
  }

  /// Set state of the creator. Typically this is used to set the state for
  /// creator with no dependency, but the framework allows setting state for any
  /// creator. No-op if the state doesn't change.
  void set<T>(CreatorBase<T> creator, T state) {
    final element = _element<T>(creator, recreate: false);
    final before = element.state;
    if (before != state) {
      element.prevState = element.state;
      element.state = state;
      element.error = null;
      _onStateChange(creator, before, state);
    }
  }

  /// Set state of creator using an update function. See [set].
  void update<T>(CreatorBase<T> creator, T Function(T) update) {
    set<T>(creator, update(_element(creator).state));
  }

  /// Recreate the state of a creator. It is typically used when things outside
  /// the graph changes. For example, click to retry after a network error.
  /// If you use this method in a creative way, let us know.
  void recreate<T>(CreatorBase<T> creator) {
    _element<T>(creator, recreate: false).recreate();
  }

  /// Try delete the creator from the graph. No-op for creators with watchers.
  /// It can delete creator even if it has keepAlive set.
  void dispose(CreatorBase creator) {
    if (_graph.from(creator).isNotEmpty) {
      return;
    }
    _delete(_graph.delete(creator));
    _delete([creator]); // In case it has no dependency and no watcher.
  }

  /// Delete all creators. Ref will become empty after this call.
  void disposeAll() {
    for (final creator in _elements.keys.toSet()) {
      _delete(_graph.delete(creator));
      _delete([creator]);
    }
  }

  /// Provide a callback which the framework will call before next create call
  /// and when the creator is disposed.
  void onClean(void Function() onClean) {
    assert(_owner != null, 'onClean is called outside of create method');
    _clean[_owner!] = onClean;
  }

  /// Delete creators which are already deleted from [_graph].
  void _delete(List<CreatorBase> creators) {
    for (final creator in creators) {
      _clean.remove(creator)?.call();
      _elements.remove(creator);
      _before.remove(creator);
      _after.remove(creator);
      _toCreate.remove(creator);
    }
  }

  /// Creator will notify Ref that they want to start creation. See [_before].
  /// Returns true if the creation is allowed.
  bool _onCreateStart<T>() {
    if (_before.containsKey(_owner!)) {
      _toCreate.add(_owner!);
      return false;
    } else {
      _before[_owner!] = Set.from(_graph.to(_owner!));
      _after[_owner!] = {};
      _clean.remove(_owner!)?.call();
      return true;
    }
  }

  /// Creator will notify Ref that they finished creation. See [_before].
  void _onCreateFinish<T>() {
    // Delete dependencies which are not needed any more.
    for (final dep in _before[_owner!] ?? {}) {
      if (!(_after[_owner!]?.contains(dep) ?? false)) {
        _delete(_graph.deleteEdge(dep, _owner!));
      }
    }
    // Start queued work if any.
    _before.remove(_owner!);
    _after.remove(_owner!);
    if (_toCreate.contains(_owner!)) {
      _toCreate.remove(_owner!);
      _element(_owner!).recreate();
    }
  }

  /// Creator will notify Ref that their state has changed. Ref will simply
  /// recreate its watchers' state. Its watcher might further call this function
  /// synchronously or asynchronously. The state change is propagated as far as
  /// we can.
  void _onStateChange<T>(CreatorBase creator, T? before, T after) {
    _observer?.onStateChange(creator, before, after);
    _notifyWatcher(creator);
  }

  /// Error was caught in user provided create function.
  void _onError<T>(CreatorBase creator, Object? error) {
    _observer?.onError(creator, error);
    _notifyWatcher(creator);
  }

  /// Propagate the state change.
  void _notifyWatcher<T>(CreatorBase creator) {
    for (final watcher in {..._graph.from(creator)}) {
      if (!_elements.containsKey(watcher)) {
        // This means watcher is a Creator and its create function is called
        // in CreatorElement's constructor, and it is not finished yet.
        continue;
      } else if (!_element(creator).created && _before.containsKey(watcher)) {
        // This means creator is actually being newly created because
        // watcher watches it during its recreate process. There is no need to
        // propagate, because watcher can get creator's state directly from
        // Ref.watch's return.
        continue;
      }
      _element(watcher).recreate();
    }
  }

  String graphString() => _graph.toString();
  String graphDebugString() => _graph.toDebugString();
  String elementsString() =>
      '{${_elements.entries.map((e) => e.key.infoName).join(', ')}}';
}

/// For testing only.
class RefForTest extends Ref {
  RefForTest() : super._();

  Map<CreatorBase, ElementBase> get elements => _elements;
  Graph<CreatorBase> get graph => _graph;
  Map<CreatorBase, Set<CreatorBase>> get before => _before;
  Map<CreatorBase, Set<CreatorBase>> get after => _after;
  Set<CreatorBase> get toCreate => _toCreate;
  Map<CreatorBase, void Function()> get clean => _clean;
}

/// For testing only.
class RefForLifeCycleTest extends Ref {
  RefForLifeCycleTest(CreatorBase owner) : super._(owner: owner);

  @override
  bool _onCreateStart<T>() => true;
  @override
  void _onCreateFinish<T>() {}
  @override
  void _onStateChange<T>(CreatorBase creator, T? before, T after) {}
}
