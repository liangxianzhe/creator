import 'package:creator_core/src/core.dart';
import 'package:test/test.dart';

void main() {
  test('creator group 1', () {
    final group = Creator.arg1<int, int>((ref, arg1) => arg1,
        name: 'foo', keepAlive: true);
    final creator = group(1);
    expect(creator.name, 'foo');
    expect(creator.keepAlive, true);
    expect(creator.args, [group, 1]);
    expect(Ref().read(creator), 1);
  });

  test('creator group 2', () {
    final group = Creator.arg2<int, int, int>((ref, arg1, arg2) => arg1 + arg2,
        name: 'foo', keepAlive: true);
    final creator = group(1, 2);
    expect(creator.name, 'foo');
    expect(creator.keepAlive, true);
    expect(creator.args, [group, 1, 2]);
    expect(Ref().read(creator), 3);
  });

  test('creator group 3', () {
    final group = Creator.arg3<int, int, int, int>(
        (ref, arg1, arg2, arg3) => arg1 + arg2 + arg3,
        name: 'foo',
        keepAlive: true);
    final creator = group(1, 2, 3);
    expect(creator.name, 'foo');
    expect(creator.keepAlive, true);
    expect(creator.args, [group, 1, 2, 3]);
    expect(Ref().read(creator), 6);
  });

  test('emitter group 1', () async {
    final group = Emitter.arg1<int, int>(
        (ref, arg1, emit) async => emit(await Future.value(arg1)),
        name: 'foo',
        keepAlive: true);
    final creator = group(1);
    expect(creator.name, 'foo');
    expect(creator.keepAlive, true);
    expect(creator.args, [group, 1]);
    expect(await Ref().read(creator), 1);
  });

  test('emitter group 2', () async {
    final group = Emitter.arg2<int, int, int>(
        (ref, arg1, arg2, emit) async => emit(await Future.value(arg1 + arg2)),
        name: 'foo',
        keepAlive: true);
    final creator = group(1, 2);
    expect(creator.name, 'foo');
    expect(creator.keepAlive, true);
    expect(creator.args, [group, 1, 2]);
    expect(await Ref().read(creator), 3);
  });

  test('emitter group 3', () async {
    final group = Emitter.arg3<int, int, int, int>(
        (ref, arg1, arg2, arg3, emit) async =>
            emit(await Future.value(arg1 + arg2 + arg3)),
        name: 'foo',
        keepAlive: true);
    final creator = group(1, 2, 3);
    expect(creator.name, 'foo');
    expect(creator.keepAlive, true);
    expect(creator.args, [group, 1, 2, 3]);
    expect(await Ref().read(creator), 6);
  });
}
