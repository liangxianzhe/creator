part of 'core.dart';

/// Base class of creators. Creators describe the graph dependencies.
/// Also see [ElementBase]. Note that T should be immutable data.
abstract class CreatorBase<T> {
  const CreatorBase({this.name, this.keepAlive = false, this.args});

  /// Name for logging purpose.
  final String? name;
  String get infoName => name ?? _argsName ?? _shortHash(this);
  String get debugName => '${name ?? _argsName ?? ''}(${_shortHash(this)})';

  /// Whether to keep the creator alive even if it loses all its watchers.
  final bool keepAlive;

  /// Creator with the same args are considered the same. args need to be
  /// unique within the graph.
  ///
  /// When a creator is defined as a local variable like this:
  /// ```dart
  /// final text = Creator((ref) {
  ///   final double = Creator((ref) => ref.watch(number) * 2);
  ///   return 'double: ${ref.watch(double)}';
  /// })
  /// ```
  /// Here double is a local variable, it has different instances whenever text
  /// is recreated. The internal graph could change from number -> double_A ->
  /// text to number -> double_B -> text as the number changes. text still
  /// generates correct data, but there is extra cost to swap the node in the
  /// graph. Because the change is localized to only one node, the cost can be
  /// ignored as long as the create function is simple.
  ///
  /// Or we can set [args] to ask the framework to find an existing creator with
  /// the same args in the graph, to avoid the extra cost.
  ///
  /// Internally, args powers these features:
  /// * Creator group.
  ///   profileCreator('userA') is a creator with args [profileCreator, 'userA'].
  /// * Async data.
  ///   userCreator.asyncData is a creator with args [userCreator, 'asyncData'].
  /// * Change.
  ///   number.change is a creator with args [number, 'change'].
  final List<Object?>? args;
  String? get _argsName => args != null ? args!.join('-') : null;

  /// See [args].
  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CreatorBase<T> &&
        (args != null ? _listEqual(args!, other.args ?? []) : super == other);
  }

  /// See [args].
  @override
  int get hashCode => (args != null) ? Object.hashAll(args!) : super.hashCode;

  /// Create its element.
  ElementBase<T> _createElement(Ref ref);
}

/// Base class of elements. Element holds the actual state. Creator and element
/// always exist as a pair in the graph.
///
/// Life cycle of creator/element:
/// - It is added to the graph when firstly being watched.
/// - It can be removed from the graph manually by [Ref.dispose].
/// - If it has watchers, it is automatically removed from the graph when losing
/// all its watchers, unless keepAlive property is set.
abstract class ElementBase<T> {
  ElementBase(this.ref, this.creator, this.state)
      : assert(ref._owner == creator);

  final Ref ref; // ref._owner is the creator
  final CreatorBase<T> creator;

  T state;
  T? prevState;
  Object? error; // Capture the exception happened during create.
  StackTrace? stackTrace; // Capture the exception happened during create.

  /// Get error-aware state.
  T getState() =>
      error != null ? Error.throwWithStackTrace(error!, stackTrace!) : state;

  /// Whether the creator has been created at least once.
  bool created = false;

  /// Allow the creator to update its state. Called when:
  /// * the element is firstly added to the graph;
  /// * one of its dependencies' state changes;
  /// * user manually demands with [Ref.recreate].
  ///
  /// The implementation should log its status by calling
  /// [Ref._onCreateStart], [Ref._onCreateFinish], [Ref._onStateChange] and
  /// [Ref._onError].
  ///
  /// If [autoDispose] is set, it should be remove from the graph after create.
  /// This parameter is set to true for [Ref.read].
  void recreate({bool autoDispose = false});
}

/// Creator creates a stream of T. It is able to return a valid state when
/// firstly being watched.
class Creator<T> extends CreatorBase<T> {
  const Creator(this.create,
      {String? name, bool keepAlive = false, List<Object?>? args})
      : super(name: name, keepAlive: keepAlive, args: args);

  /// Create a [Creator] with an initial value.
  Creator.value(T t,
      {String? name, bool keepAlive = false, List<Object?>? args})
      : this((ref) => t, name: name, keepAlive: keepAlive, args: args);

  final T Function(Ref) create;

  @override
  CreatorElement<T> _createElement(Ref ref) => CreatorElement<T>(ref, this);
}

/// Creator's element.
class CreatorElement<T> extends ElementBase<T> {
  // Note here we call create function to get the initial state.
  CreatorElement(ref, Creator<T> creator)
      : super(ref, creator, creator.create(ref));

  @override
  void recreate({CreatorBase? reason, bool autoDispose = false}) {
    error = null;
    stackTrace = null;
    if (!created) {
      // No need to recreate if initializing, since create is called in
      // constructor already.
      ref._onStateChange(creator, prevState, state);
    } else {
      if (!ref._onCreateStart()) {
        // Return if creation is not allowed, i.e. another job is in progress.
        return;
      }
      try {
        final newState = (creator as Creator<T>).create(ref);
        if (newState != state) {
          prevState = state;
          state = newState;
          ref._onStateChange(creator, prevState, state);
        }
      } catch (error, stackTrace) {
        this.error = error;
        this.stackTrace = stackTrace;
        ref._onError(creator, error, stackTrace);
      }
    }
    if (autoDispose && !creator.keepAlive) {
      ref.dispose(creator);
    }
    if (created) {
      ref._onCreateFinish();
    }
    created = true;
  }
}

/// Emitter creates a stream of Future<T>.
///
/// When an emitter firstly being watched, it create an empty future, which is
/// completed by the first emit call. Subsequence emit call will update its
/// state to Future.value.
///
/// This means that when emitter notifies its watcher about a state change, its
/// watcher gets a Future.value, which can resolves immediately.
class Emitter<T> extends CreatorBase<Future<T>> {
  const Emitter(this.create,
      {String? name, bool keepAlive = false, List<Object?>? args})
      : super(name: name, keepAlive: keepAlive, args: args);

  /// Create an [Emitter] from an existing stream. It works both sync and async.
  ///
  /// ```dart
  /// final authCreator = Emitter.stream(
  ///   (ref) => FirebaseAuth.instance.authStateChanges());
  /// final userCreator = Emitter.stream((ref) async {
  ///   final uid = await ref.watch(
  ///     authCreator.where((auth) => auth != null)).map((auth) => auth!.uid);
  ///   return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  /// });
  /// ```
  Emitter.stream(FutureOr<Stream<T>> Function(Ref) stream,
      {String? name, bool keepAlive = false, List<Object?>? args})
      : this((ref, emit) async {
          final sub = (await stream(ref)).listen((value) => emit(value),
              onError: (error, stackTrace) {
            emit(null, error, stackTrace);
          });
          ref.onClean(sub.cancel);
        }, name: name, keepAlive: keepAlive, args: args);

  /// User provided create function. It can use ref to get data from the graph
  /// then call emit to push data to the graph. emit can be called multiple
  /// times. If error is set, value is ignored.
  final FutureOr<void> Function(Ref ref,
      void Function(T?, [Object? error, StackTrace? stackTrace]) emit) create;

  @override
  EmitterElement<T> _createElement(Ref ref) =>
      EmitterElement<T>(ref, this, Completer());
}

/// Emitter's element.
class EmitterElement<T> extends ElementBase<Future<T>> {
  EmitterElement(ref, Emitter<T> creator, this.completer)
      : super(ref, creator, completer.future);

  /// This Completer produces a empty future in the constructor, then complete
  /// the future when the first state is emitted. In other words, an
  /// Emitter generates these states in sequence:
  /// 1. Future<T> (completer.future, completed by the first emit() call)
  /// 2. Future.value<T> (a new future, with data from the second emit() call)
  /// 3. ... then always Future.value<T>, unless error happens.
  final Completer<T> completer;

  /// Emitted value. Base class already saves Future<T> already, we save T here.
  T? value;
  T? prevValue;

  /// The emit function which could be called in user provided create function.
  void emit(T? newValue, [Object? error, StackTrace? stackTrace]) {
    if (error != null) {
      if (!created) {
        // Error happens before any emit calls, let's wake up awaiting watchers.
        completer.completeError(error, stackTrace);
      }
      ref._onError(creator, error, stackTrace);
    } else {
      if (created && value == newValue) {
        return; // Nothing changes
      }
      if (!created) {
        // emit is called the first time, let's wake up awaiting watchers.
        completer.complete(newValue);
      } else {
        prevState = state;
        state = Future<T>.value(newValue);
      }
      prevValue = value;
      value = newValue;
      ref._onStateChange(creator, prevValue, value);
    }
    this.error = error;
    this.stackTrace = stackTrace;

    // Emitter is considered created as long as emit is called once, even for errors.
    created = true;
  }

  @override
  Future<void> recreate({bool autoDispose = false}) async {
    // Return if creation is not allowed, i.e. another job is in progress.
    if (!ref._onCreateStart()) {
      return;
    }
    error = null;
    stackTrace = null;
    try {
      await (creator as Emitter<T>).create(ref, emit);
    } catch (error, stackTrace) {
      this.error = error;
      this.stackTrace = stackTrace;
      ref._onError(creator, error, stackTrace);
    }
    if (autoDispose && !creator.keepAlive) {
      ref.dispose(creator);
    }
    ref._onCreateFinish();
  }
}

/// Change wraps current state and previous state.
class Change<T> {
  const Change(this.before, this.after);
  final T? before;
  final T after;

  @override
  int get hashCode => Object.hashAll([before, after]);

  @override
  bool operator ==(dynamic other) =>
      other is Change<T> && before == other.before && after == other.after;

  @override
  String toString() => '$before->$after';
}

extension CreatorChange<T> on Creator<T> {
  /// Return Creator<Change<T>>, which has both prev state and current state.
  Creator<Change<T>> get change {
    return Creator((ref) {
      ref.watch(this);
      final element = ref._element(this) as CreatorElement<T>;
      return Change(element.prevState, element.state);
    }, name: '${infoName}_change', args: [this, 'change']);
  }
}

extension EmitterChange<T> on Emitter<T> {
  /// Return Emitter<Change<T>>, which has both prev state and current state.
  Emitter<Change<T>> get change {
    return Emitter((ref, emit) async {
      await ref.watch(this); // Wait to ensure first value is emitted
      final element = ref._element(this) as EmitterElement<T>;
      emit(Change(element.prevValue, element.value as T));
    }, name: '${infoName}_change', args: [this, 'change']);
  }
}

extension EmitterAsyncData<T> on Emitter<T> {
  /// Creator of AsyncData<T>, whose state can be "waiting" if the emitter has
  /// no data yet. Use AsyncData<T> instead T? because T could be nullable.
  Creator<AsyncData<T>> get asyncData {
    return Creator((ref) {
      ref.watch(this);
      final element = ref._element(this) as EmitterElement<T>;
      return element.completer.isCompleted
          ? AsyncData.withData(element.value as T)
          : const AsyncData.waiting();
    }, name: '${infoName}_asyncData', args: [this, 'asyncData']);
  }
}

/// Copied from Flutter. [Object.hashCode]'s 20 least-significant bits.
String _shortHash(Object? object) =>
    object.hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');

/// Check whether two lists are equal.
bool _listEqual(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
