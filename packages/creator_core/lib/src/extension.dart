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

  Emitter<F> mapAsync<F>(Future<F> Function(T) map,
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

  Emitter<F> where<F>(bool Function(T) test,
      {String? name, bool keepAlive = false, List<Object?>? args}) {
    return Emitter(<F>(ref, emit) {
      return ref.watch(this).then((value) {
        if (test(value)) {
          emit(value as F);
        }
      });
    }, name: name ?? '${infoName}_where', keepAlive: keepAlive, args: args);
  }
}
