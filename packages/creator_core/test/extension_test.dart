import 'package:creator_core/src/core.dart';
import 'package:creator_core/src/extension.dart';
import 'package:test/test.dart';

void main() {
  test('creator map', () {
    final number = Creator.value(1);
    final double = number.map((n) => n * 2, name: 'double', keepAlive: true);
    expect(double.name, 'double');
    expect(double.keepAlive, true);

    final ref = Ref();
    expect(ref.watch(double), 2);
    ref.set(number, 2);
    expect(ref.watch(double), 4);
  });

  test('creator mapAsync', () async {
    final number = Creator.value(1);
    final double = number.mapAsync((n) => Future.value(n * 2),
        name: 'double', keepAlive: true);
    expect(double.name, 'double');
    expect(double.keepAlive, true);

    final ref = Ref();
    expect(await ref.watch(double), 2);
    ref.set(number, 2);
    await Future.delayed(const Duration());
    expect(await ref.watch(double), 4);
  });

  test('creator where', () async {
    final number = Creator.value(0);
    final odd = number.where((n) => n.isOdd, name: 'odd', keepAlive: true);
    expect(odd.name, 'odd');
    expect(odd.keepAlive, true);

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

  test('emitter map', () async {
    final number = Emitter<int>(((ref, emit) => emit(1)));
    final double = number.map((n) => n * 2, name: 'double', keepAlive: true);
    expect(double.name, 'double');
    expect(double.keepAlive, true);

    final ref = Ref();
    expect(await ref.watch(double), 2);
    ref.set(number, Future.value(2));
    await Future.delayed(const Duration());
    expect(await ref.watch(double), 4);
  });

  test('emitter where', () async {
    final number = Emitter<int>(((ref, emit) => emit(1)));
    final odd = number.where((n) => n.isOdd, name: 'odd', keepAlive: true);
    expect(odd.name, 'odd');
    expect(odd.keepAlive, true);

    final ref = Ref();
    ref.watch(odd);
    expect(ref.watch(odd), completion(1)); // Complete later when set number

    ref.set(number, Future.value(1));
    await Future.delayed(const Duration());
    expect(await ref.watch(odd), 1);

    ref.set(number, Future.value(2));
    await Future.delayed(const Duration());
    expect(await ref.watch(odd), 1); // Ignore even number

    ref.set(number, Future.value(3));
    await Future.delayed(const Duration());
    expect(await ref.watch(odd), 3);
  });
}
