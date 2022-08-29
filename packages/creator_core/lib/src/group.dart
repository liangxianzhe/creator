part of 'core.dart';

// This file is just to make creator group works. It is not super interesting.
// Put it here instead of inside Creator/Emitter classes for readability.

class _CreatorGroup1<T, A1> {
  const _CreatorGroup1(this.create, this.name, this.keepAlive);
  final T Function(Ref, A1 arg1) create;
  final String Function(A1)? name;
  final bool keepAlive;
  Creator<T> call(A1 arg1) => Creator<T>((ref) => create(ref, arg1),
      name: name?.call(arg1), keepAlive: keepAlive, args: [this, arg1]);
}

class _CreatorWithArg1 {
  const _CreatorWithArg1();
  _CreatorGroup1<T, A1> call<T, A1>(T Function(Ref, A1 arg1) create,
      {String Function(A1)? name, bool keepAlive = false}) {
    return _CreatorGroup1<T, A1>(create, name, keepAlive);
  }
}

class _CreatorGroup2<T, A1, A2> {
  const _CreatorGroup2(this.create, this.name, this.keepAlive);
  final T Function(Ref, A1 arg1, A2 arg2) create;
  final String Function(A1, A2)? name;
  final bool keepAlive;
  Creator<T> call(A1 arg1, A2 arg2) =>
      Creator<T>((ref) => create(ref, arg1, arg2),
          name: name?.call(arg1, arg2),
          keepAlive: keepAlive,
          args: [this, arg1, arg2]);
}

class _CreatorWithArg2 {
  const _CreatorWithArg2();
  _CreatorGroup2<T, A1, A2> call<T, A1, A2>(
      T Function(Ref, A1 arg1, A2 arg2) create,
      {String Function(A1, A2)? name,
      bool keepAlive = false}) {
    return _CreatorGroup2<T, A1, A2>(create, name, keepAlive);
  }
}

class _CreatorGroup3<T, A1, A2, A3> {
  const _CreatorGroup3(this.create, this.name, this.keepAlive);
  final T Function(Ref, A1 arg1, A2 arg2, A3 arg3) create;
  final String Function(A1, A2, A3)? name;
  final bool keepAlive;
  Creator<T> call(A1 arg1, A2 arg2, A3 arg3) =>
      Creator<T>((ref) => create(ref, arg1, arg2, arg3),
          name: name?.call(arg1, arg2, arg3),
          keepAlive: keepAlive,
          args: [this, arg1, arg2, arg3]);
}

class _CreatorWithArg3 {
  const _CreatorWithArg3();
  _CreatorGroup3<T, A1, A2, A3> call<T, A1, A2, A3>(
      T Function(Ref, A1 arg1, A2 arg2, A3 arg3) create,
      {String Function(A1, A2, A3)? name,
      bool keepAlive = false}) {
    return _CreatorGroup3<T, A1, A2, A3>(create, name, keepAlive);
  }
}

class _EmitterGroup1<T, A1> {
  const _EmitterGroup1(this.create, this.name, this.keepAlive);
  final FutureOr<void> Function(Ref ref, A1 arg1, void Function(T) emit) create;
  final String Function(A1)? name;
  final bool keepAlive;
  Emitter<T> call(A1 arg1) => Emitter<T>((ref, emit) => create(ref, arg1, emit),
      name: name?.call(arg1), keepAlive: keepAlive, args: [this, arg1]);
}

class _EmitterWithArg1 {
  const _EmitterWithArg1();
  _EmitterGroup1<T, A1> call<T, A1>(
      FutureOr<void> Function(Ref ref, A1 arg1, void Function(T) emit) create,
      {String Function(A1)? name,
      bool keepAlive = false}) {
    return _EmitterGroup1<T, A1>(create, name, keepAlive);
  }
}

class _EmitterGroup2<T, A1, A2> {
  const _EmitterGroup2(this.create, this.name, this.keepAlive);
  final FutureOr<void> Function(
      Ref ref, A1 arg1, A2 arg2, void Function(T) emit) create;
  final String Function(A1, A2)? name;
  final bool keepAlive;
  Emitter<T> call(A1 arg1, A2 arg2) =>
      Emitter<T>((ref, emit) => create(ref, arg1, arg2, emit),
          name: name?.call(arg1, arg2),
          keepAlive: keepAlive,
          args: [this, arg1, arg2]);
}

class _EmitterWithArg2 {
  const _EmitterWithArg2();
  _EmitterGroup2<T, A1, A2> call<T, A1, A2>(
      FutureOr<void> Function(Ref ref, A1 arg1, A2 arg2, void Function(T) emit)
          create,
      {String Function(A1, A2)? name,
      bool keepAlive = false}) {
    return _EmitterGroup2<T, A1, A2>(create, name, keepAlive);
  }
}

class _EmitterGroup3<T, A1, A2, A3> {
  const _EmitterGroup3(this.create, this.name, this.keepAlive);
  final FutureOr<void> Function(
      Ref ref, A1 arg1, A2 arg2, A3 arg3, void Function(T) emit) create;
  final String Function(A1, A2, A3)? name;
  final bool keepAlive;
  Emitter<T> call(A1 arg1, A2 arg2, A3 arg3) =>
      Emitter<T>((ref, emit) => create(ref, arg1, arg2, arg3, emit),
          name: name?.call(arg1, arg2, arg3),
          keepAlive: keepAlive,
          args: [this, arg1, arg2, arg3]);
}

class _EmitterWithArg3 {
  const _EmitterWithArg3();
  _EmitterGroup3<T, A1, A2, A3> call<T, A1, A2, A3>(
      FutureOr<void> Function(
              Ref ref, A1 arg1, A2 arg2, A3 arg3, void Function(T) emit)
          create,
      {String Function(A1, A2, A3)? name,
      bool keepAlive = false}) {
    return _EmitterGroup3<T, A1, A2, A3>(create, name, keepAlive);
  }
}
