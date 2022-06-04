import 'core.dart';

/// {@template extension}
/// Higher level primitives similar to these methods in [Iterable] / [Stream].
/// These methods are simple, but hopefully can make code concise and fluid.
///
/// If you use extensions on the fly, you should understand creator equality
/// and set [CreatorBase.args] as needed.
/// {@endtemplate}

/// {@macro extension}
extension CreatorExtension<T> on Creator<T> {
  Creator<F> map<F>(F Function(T) map,
      {String? name, bool keepAlive = false, List<Object?>? args}) {
    return Creator((ref) => map(ref.watch(this)),
        name: name ?? '${infoName}_map', keepAlive: keepAlive, args: args);
  }

  Emitter<F> asyncMap<F>(Future<F> Function(T) map,
      {String? name, bool keepAlive = false, List<Object?>? args}) {
    return Emitter<F>((ref, emit) async => emit(await map(ref.watch(this))),
        name: name ?? '${infoName}_map', keepAlive: keepAlive, args: args);
  }

  Emitter<T> where(bool Function(T) test,
      {String? name, bool keepAlive = false, List<Object?>? args}) {
    return Emitter<T>((ref, emit) {
      final value = ref.watch(this);
      if (test(value)) {
        emit(value);
      }
    }, name: name ?? '${infoName}_where', keepAlive: keepAlive, args: args);
  }

  /// Set args to some unique value if creator is used on the fly, or null if
  /// the creator defined in a stable variable. See [CreatorBase.args].
  Creator<T> reduce(
      T Function(T previous, T element) combine, List<Object?>? args,
      {String? name, bool keepAlive = false}) {
    return Creator((ref) {
      final previous = ref.readSelf();
      final element = ref.watch(this);
      if (previous == null) {
        return element;
      } else {
        return combine(previous, element);
      }
    }, name: name ?? '${infoName}_reduce', keepAlive: keepAlive, args: args);
  }
}

/// {@macro extension}
extension EmitterExtension<T> on Emitter<T> {
  Emitter<F> map<F>(F Function(T) map,
      {String? name, bool keepAlive = false, List<Object?>? args}) {
    return Emitter<F>(
        (ref, emit) => ref.watch(this).then((value) => emit(map(value))),
        name: name ?? '${infoName}_map',
        keepAlive: keepAlive,
        args: args);
  }

  Emitter<F> asyncMap<F>(Future<F> Function(T) map,
      {String? name, bool keepAlive = false, List<Object?>? args}) {
    return Emitter<F>(
        (ref, emit) =>
            ref.watch(this).then((value) => map(value).then((v) => emit(v))),
        name: name ?? '${infoName}_map',
        keepAlive: keepAlive,
        args: args);
  }

  Emitter<F> where<F>(bool Function(T) test,
      {String? name, bool keepAlive = false, List<Object?>? args}) {
    return Emitter<F>(<F>(ref, emit) {
      ref.watch(this).then((value) {
        if (test(value)) {
          emit(value as F);
        }
      });
    }, name: name ?? '${infoName}_where', keepAlive: keepAlive, args: args);
  }

  /// Set args to some unique value if creator is used on the fly, or null if
  /// the creator defined in a stable variable. See [CreatorBase.args].
  Emitter<T> reduce(
      T Function(T previous, T element) combine, List<Object?>? args,
      {String? name, bool keepAlive = false}) {
    return Emitter<T>((ref, emit) async {
      final previous = ref.readSelf();
      final element = await ref.watch(this);
      if (previous == null) {
        emit(element);
      } else {
        emit(combine(previous, element));
      }
    }, name: name ?? '${infoName}_map', keepAlive: keepAlive, args: args);
  }

  Emitter<F> expand<F>(Iterable<F> Function(T) convert,
      {String? name, bool keepAlive = false, List<Object?>? args}) {
    return Emitter<F>((ref, emit) {
      ref.watch(this).then((value) {
        for (var v in convert(value)) {
          emit(v);
        }
      });
    }, name: name ?? '${infoName}_expand', keepAlive: keepAlive, args: args);
  }
}
