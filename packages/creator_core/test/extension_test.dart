import 'package:creator_core/src/core.dart';
import 'package:creator_core/src/extension.dart';
import 'package:test/test.dart';

void main() {
  test('creator map', () {
    final number = Creator.value(1, name: 'number');
    final double = number.map((n) => n * 2, keepAlive: true);
    expect(double.name, 'number_map');
    expect(double.keepAlive, true);
    expect(double.args, null);

    final ref = Ref();
    expect(ref.watch(double), 2);
    ref.set(number, 2);
    expect(ref.watch(double), 4);
  });

  test('creator asyncMap', () async {
    final number = Creator.value(1, name: 'number');
    final double = number.asyncMap((n) => Future.value(n * 2), keepAlive: true);
    expect(double.name, 'number_map');
    expect(double.keepAlive, true);
    expect(double.args, null);

    final ref = Ref();
    expect(await ref.watch(double), 2);
    ref.set(number, 2);
    await Future.delayed(const Duration());
    expect(await ref.watch(double), 4);
  });

  test('creator where', () async {
    final number = Creator.value(0, name: 'number');
    final odd = number.where((n) => n.isOdd, keepAlive: true);
    expect(odd.name, 'number_where');
    expect(odd.keepAlive, true);
    expect(odd.args, null);

    final ref = Ref();
    ref.watch(odd);
    expect(ref.watch(odd), completion(1)); // Complete later when set number

    ref.set(number, 1);
    await Future.delayed(const Duration());
    expect(await ref.watch(odd), 1);

    ref.set(number, 2);
    await Future.delayed(const Duration());
    expect(await ref.watch(odd), 1); // Ignore even number

    ref.set(number, 3);
    await Future.delayed(const Duration());
    expect(await ref.watch(odd), 3);
  });

  test('creator reduce', () {
    final number = Creator.value(1, name: 'number');
    final sum = number.reduce((previous, element) => previous + element, null,
        keepAlive: true);
    expect(sum.name, 'number_reduce');
    expect(sum.keepAlive, true);
    expect(sum.args, null);

    final ref = Ref();
    expect(ref.watch(sum), 1);
    ref.set(number, 2);
    expect(ref.watch(sum), 3);
    ref.set(number, 3);
    expect(ref.watch(sum), 6);
  });

  test('emitter map', () async {
    final number = Emitter<int>((ref, emit) => emit(1), name: 'number');
    final double = number.map((n) => n * 2, keepAlive: true);
    expect(double.name, 'number_map');
    expect(double.keepAlive, true);
    expect(double.args, null);

    final ref = Ref();
    expect(await ref.watch(double), 2);
    ref.emit(number, 2);
    await Future.delayed(const Duration());
    expect(await ref.watch(double), 4);
  });

  test('emitter asyncMap', () async {
    final number = Emitter<int>((ref, emit) => emit(1), name: 'number');
    final double = number.asyncMap((n) => Future.value(n * 2), keepAlive: true);
    expect(double.name, 'number_map');
    expect(double.keepAlive, true);
    expect(double.args, null);

    final ref = Ref();
    expect(await ref.watch(double), 2);
    ref.emit(number, 2);
    await Future.delayed(const Duration());
    expect(await ref.watch(double), 4);
  });

  test('emitter where', () async {
    final number = Emitter<int>((ref, emit) => emit(1), name: 'number');
    final odd = number.where((n) => n.isOdd, keepAlive: true);
    expect(odd.name, 'number_where');
    expect(odd.keepAlive, true);
    expect(odd.args, null);

    final ref = Ref();
    ref.watch(odd);
    expect(ref.watch(odd), completion(1)); // Complete later when set number

    ref.emit(number, 1);
    await Future.delayed(const Duration());
    expect(await ref.watch(odd), 1);

    ref.emit(number, 2);
    await Future.delayed(const Duration());
    expect(await ref.watch(odd), 1); // Ignore even number

    ref.emit(number, 3);
    await Future.delayed(const Duration());
    expect(await ref.watch(odd), 3);
  });

  test('emitter reduce', () async {
    final number = Emitter<int>((ref, emit) => emit(1), name: 'number');
    final sum = number.reduce((previous, element) => previous + element, null,
        keepAlive: true);
    expect(sum.name, 'number_reduce');
    expect(sum.keepAlive, true);
    expect(sum.args, null);

    final ref = Ref();
    expect(await ref.watch(sum), 1);
    ref.emit(number, 2);
    await Future.delayed(const Duration());
    expect(await ref.watch(sum), 3);
    ref.emit(number, 3);
    await Future.delayed(const Duration());
    expect(await ref.watch(sum), 6);
  });

  test('emitter expand', () async {
    final result = <int>[];
    final number = Emitter<int>((ref, emit) => emit(1), name: 'number');
    final double = number.expand((n) => [n, 2 * n], keepAlive: true);
    final watcher = double.map((n) {
      result.add(n);
      return n;
    });
    expect(double.name, 'number_expand');
    expect(double.keepAlive, true);
    expect(double.args, null);

    final ref = Ref();
    expect(await ref.watch(watcher), 1);
    ref.emit(number, 10);
    await Future.delayed(const Duration());
    expect(await ref.watch(watcher), 20);
    ref.emit(number, 100);
    await Future.delayed(const Duration());
    expect(await ref.watch(watcher), 200);
    expect(result, [1, 2, 10, 20, 100, 200]);
  });
}
