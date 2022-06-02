import 'package:creator_core/src/async_data.dart';
import 'package:creator_core/src/core.dart';
import 'package:test/test.dart';

void expectEmpty(RefForTest ref) {
  expect(ref.elements, isEmpty);
  expect(ref.graph.nodes, isEmpty);
  expect(ref.before, isEmpty);
  expect(ref.after, isEmpty);
  expect(ref.toCreate, isEmpty);
  expect(ref.clean, isEmpty);
}

void main() {
  group('read', () {
    test('read creator', () {
      final ref = RefForTest();
      final creator = Creator.value(1);

      expect(ref.read(creator), 1);
      expectEmpty(ref);
    });

    test('read emitter', () async {
      final ref = RefForTest();
      final creator =
          Emitter<int>(((ref, emit) async => emit(await Future.value(1))));

      expect(await ref.read(creator), 1);
      expectEmpty(ref);
    });

    test('read creator with dependency', () {
      final ref = RefForTest();
      final a = Creator.value(1);
      final b = Creator(((ref) => ref.watch(a) * 2));
      final c = Creator(((ref) => ref.watch(b) * 2));

      expect(ref.read(c), 4);
      expectEmpty(ref);
    });

    test('read emitter with dependency', () async {
      final ref = RefForTest();
      final a = Emitter<int>((ref, emit) => emit(1));
      final b =
          Emitter<int>(((ref, emit) async => emit(await ref.watch(a) * 2)));
      final c =
          Emitter<int>(((ref, emit) async => emit(await ref.watch(b) * 2)));

      expect(await ref.read(c), 4);
      expectEmpty(ref);
    });

    test('read existing creator should not dispose it', () {
      final ref = RefForTest();
      final creator = Creator.value(1);
      ref.watch(creator);
      expect(ref.read(creator), 1);
      expect(ref.elements.keys, {creator});
    });

    test('read keep alive creator should not dispose it', () {
      final ref = RefForTest();
      final creator = Creator.value(1, keepAlive: true);
      expect(ref.read(creator), 1);
      expect(ref.elements.keys, {creator});
    });
  });

  group('read self', () {
    test('read self for creator', () {
      final ref = RefForTest();
      final creator = Creator(((ref) {
        return (ref.readSelf() ?? 0) + 1;
      }));

      expect(ref.watch(creator), 1);
      ref.recreate(creator);
      expect(ref.watch(creator), 2);
      ref.recreate(creator);
      expect(ref.watch(creator), 3);
    });

    test('read self for emitter', () async {
      final ref = RefForTest();
      final creator = Emitter<int>(((ref, emit) async {
        emit((ref.readSelf() ?? 0) + await Future.value(1));
      }));

      expect(await ref.watch(creator), 1);
      ref.recreate(creator);
      await Future.delayed(const Duration());
      expect(await ref.watch(creator), 2);
      ref.recreate(creator);
      await Future.delayed(const Duration());
      expect(await ref.watch(creator), 3);
    });
  });

  group('watch', () {
    test('watch creator', () {
      final ref = RefForTest();
      final creator = Creator.value(1);

      expect(ref.watch(creator), 1);
      expect(ref.elements.keys, {creator});
      expect(ref.graph, isNot(contains(creator)));
      expect(ref.before, isEmpty);
      expect(ref.after, isEmpty);
      expect(ref.toCreate, isEmpty);
      expect(ref.clean, isEmpty);
    });

    test('watch emitter', () async {
      final ref = RefForTest();
      final creator =
          Emitter<int>(((ref, emit) async => emit(await Future.value(1))));

      expect(await ref.watch(creator), 1);
      expect(ref.elements.keys, {creator});
      expect(ref.graph, isNot(contains(creator)));
      expect(ref.before, isEmpty);
      expect(ref.after, isEmpty);
      expect(ref.toCreate, isEmpty);
      expect(ref.clean, isEmpty);
    });

    test('watch creator with dependency', () {
      final ref = RefForTest();
      final a = Creator.value(1);
      final b = Creator(((ref) => ref.watch(a) * 2));
      final c = Creator(((ref) => ref.watch(b) * 2));

      expect(ref.watch(c), 4);
      expect(ref.elements.keys, {a, b, c});
      expect(ref.graph.from(a), {b});
      expect(ref.graph.from(b), {c});
      expect(ref.before, isEmpty);
      expect(ref.after, isEmpty);
      expect(ref.toCreate, isEmpty);
      expect(ref.clean, isEmpty);
    });

    test('watch emitter with dependency', () async {
      final ref = RefForTest();
      final a = Emitter<int>((ref, emit) async => emit(await Future.value(1)));
      final b =
          Emitter<int>(((ref, emit) async => emit(await ref.watch(a) * 2)));
      final c =
          Emitter<int>(((ref, emit) async => emit(await ref.watch(b) * 2)));

      expect(await ref.watch(c), 4);
      expect(ref.graph.from(a), {b});
      expect(ref.graph.from(b), {c});
      expect(ref.before, isEmpty);
      expect(ref.after, isEmpty);
      expect(ref.toCreate, isEmpty);
      expect(ref.clean, isEmpty);
    });

    test('watch creator with dynamic dependency', () {
      final ref = RefForTest();
      final a = Creator.value(1);
      final b = Creator.value(2);
      final c = Creator(((ref) {
        return ref.watch(a) > 0 ? ref.watch(a) : ref.watch(b);
      }));

      expect(ref.watch(c), 1);
      expect(ref.elements.keys, {a, c});
      expect(ref.graph.from(a), {c});
      expect(ref.graph.from(b), isEmpty);

      ref.set(a, -1);
      expect(ref.watch(c), 2);
      expect(ref.elements.keys, {a, b, c});
      expect(ref.graph.from(a), {c});
      expect(ref.graph.from(b), {c});

      ref.set(a, 1);
      expect(ref.watch(c), 1);
      expect(ref.elements.keys, {a, c});
      expect(ref.graph.from(a), {c});
      expect(ref.graph.from(b), isEmpty);
    });

    test('watch emitter with dynamic dependency', () async {
      final ref = RefForTest();
      final a = Emitter<int>((ref, emit) async => emit(await Future.value(1)));
      final b = Emitter<int>((ref, emit) async => emit(await Future.value(2)));
      final c = Emitter<int>(((ref, emit) async {
        final value = await ref.watch(a);
        emit(value > 0 ? value : await ref.watch(b));
      }));

      expect(await ref.watch(c), 1);
      expect(ref.elements.keys, {a, c});
      expect(ref.graph.from(a), {c});
      expect(ref.graph.from(b), isEmpty);

      ref.set(a, Future.value(-1));
      await Future.delayed(const Duration());
      expect(await ref.watch(c), 2);
      expect(ref.elements.keys, {a, b, c});
      expect(ref.graph.from(a), {c});
      expect(ref.graph.from(b), {c});

      ref.set(a, Future.value(1));
      await Future.delayed(const Duration());
      expect(await ref.watch(c), 1);
      expect(ref.elements.keys, {a, c});
      expect(ref.graph.from(a), {c});
      expect(ref.graph.from(b), isEmpty);
    });

    test('watch emitter from stream', () async {
      final ref = RefForTest();
      final stream = Stream.fromIterable([1, 2]);
      final emitter = Emitter.stream((ref) => stream);

      expect(await ref.watch(emitter), 1);
      await Future.delayed(const Duration());
      expect(await ref.watch(emitter), 2);
    });

    test('watch complex graph', () async {
      //  C1 (1)         ->  C2 (= C1 * 2 = 2)   ->  C3 (= C2 * 2 = 4)
      //   ↓                  ↓                       ↓
      //  E1 (= C1 = 1)  ->  E2 (= E1 + C2 = 3)  ->  E3 (= E2 + C3 = 7)
      final ref = RefForTest();
      Map<String, int> called = {};

      final c1 = Creator((ref) {
        called['c1'] = (called['c1'] ?? 0) + 1;
        return 1;
      }, name: 'c1');
      final c2 = Creator((ref) {
        called['c2'] = (called['c2'] ?? 0) + 1;
        return ref.watch(c1) * 2;
      }, name: 'c2');
      final c3 = Creator((ref) {
        called['c3'] = (called['c3'] ?? 0) + 1;
        return ref.watch(c2) * 2;
      }, name: 'c3');

      final e1 = Emitter<int>(((ref, emit) async {
        called['e1'] = (called['e1'] ?? 0) + 1;
        emit(ref.watch(c1));
      }), name: 'e1');
      final e2 = Emitter<int>(((ref, emit) async {
        called['e2'] = (called['e2'] ?? 0) + 1;
        emit(ref.watch(c2) + await ref.watch(e1));
      }), name: 'e2');
      final e3 = Emitter<int>(((ref, emit) async {
        called['e3'] = (called['e3'] ?? 0) + 1;
        emit(ref.watch(c3) + await ref.watch(e2));
      }), name: 'e3');

      expect(await ref.watch(e3), 7);
      expect(called, {'c1': 1, 'c2': 1, 'c3': 1, 'e1': 1, 'e2': 1, 'e3': 1});

      // Note that only one edge can change at a time, so e2 changed twice due
      // c2 and e1. Similarly, e3 changed 3 times.
      called.clear();
      ref.set(c1, 2);
      await Future.delayed(const Duration());
      expect(called, {'c2': 1, 'c3': 1, 'e1': 1, 'e2': 2, 'e3': 3});
      expect(await ref.watch(e3), 14);

      ref.dispose(e3);
      expectEmpty(ref);
    });
  });

  group('set', () {
    test('set creator', () {
      final ref = RefForTest();
      final a = Creator.value(1);
      final b = Creator(((ref) => ref.watch(a) * 2));

      expect(ref.watch(a), 1);
      expect(ref.watch(b), 2);

      ref.set(a, 10);
      expect(ref.watch(a), 10);
      expect(ref.watch(b), 20);
    });

    test('set emitter', () async {
      final ref = RefForTest();
      final a = Emitter<int>((ref, emit) async => emit(await Future.value(1)));
      final b = Emitter<int>((ref, emit) async => emit(await ref.watch(a) * 2));

      expect(await ref.watch(a), 1);
      expect(await ref.watch(b), 2);

      ref.set(a, Future.value(10));
      await Future.delayed(const Duration());
      expect(await ref.watch(a), 10);
      expect(await ref.watch(b), 20);
    });

    test('no op if value is the same', () {
      final ref = RefForTest();
      final a = Creator.value(1);
      final multi = [2];
      final b = Creator(((ref) => ref.watch(a) * multi.removeAt(0)));

      expect(ref.watch(a), 1);
      expect(ref.watch(b), 2);

      ref.set(a, 1);
      expect(ref.watch(a), 1);
      expect(ref.watch(b), 2);
    });

    test('set adds creator to graph', () {
      final ref = RefForTest();
      final a = Creator.value(1);
      ref.set(a, 10);
      expect(ref.read(a), 10);
      expect(ref.elements, contains(a));
    });

    test('recreate is not called when set', () async {
      final ref = RefForTest();
      final a = Emitter<int>((ref, emit) async => emit(await Future.error('')));
      ref.set(a, Future.value(1));
      await Future.delayed(const Duration());
      expect(await ref.read(a), 1);
      expect(ref.elements, contains(a));
    });
  });

  group('update', () {
    test('update creator', () {
      final ref = RefForTest();
      final a = Creator.value(1);
      final b = Creator(((ref) => ref.watch(a) * 2));

      expect(ref.watch(a), 1);
      expect(ref.watch(b), 2);

      ref.update<int>(a, (n) => n + 9);
      expect(ref.watch(a), 10);
      expect(ref.watch(b), 20);
    });
  });

  group('recreate', () {
    test('recreate creator', () {
      final ref = RefForTest();
      final value = [1, 2];
      final a = Creator(((ref) => value.removeAt(0)));

      expect(ref.watch(a), 1);

      ref.recreate(a);
      expect(ref.watch(a), 2);
    });

    test('recreate emitter', () async {
      final ref = RefForTest();
      final value = [1, 2];
      final a = Emitter<int>(
          (ref, emit) async => emit(await Future.value(value.removeAt(0))));

      expect(await ref.watch(a), 1);

      ref.recreate(a);
      await Future.delayed(const Duration());
      expect(await ref.watch(a), 2);
    });

    test('recreate adds creator to graph', () {
      final ref = RefForTest();
      final value = [1];
      final a = Creator(((ref) => value.removeAt(0)));

      ref.recreate(a);
      expect(ref.read(a), 1);
      expect(ref.elements, contains(a));
    });

    test('recreate adds emitter to the graph', () async {
      final ref = RefForTest();
      final value = [1];
      final a = Emitter<int>(
          (ref, emit) async => emit(await Future.value(value.removeAt(0))));

      ref.recreate(a);
      await Future.delayed(const Duration());
      expect(await ref.watch(a), 1);
      expect(ref.elements, contains(a));
    });

    test('does not propagate if value is the same for creator', () {
      final ref = RefForTest();
      final value = [2];
      final a = Creator.value(1);
      final b = Creator(((ref) => ref.watch(a) * value.removeAt(0)));

      expect(ref.watch(b), 2);
      ref.recreate(a);
      expect(ref.watch(b), 2);
    });

    test('does not propagate if value is the same for emitter', () async {
      final ref = RefForTest();
      final value = [2];
      final a = Creator.value(1);
      final b = Emitter<int>((ref, emit) async =>
          emit(ref.watch(a) * await Future.value(value.removeAt(0))));

      expect(await ref.watch(b), 2);

      ref.recreate(a);
      await Future.delayed(const Duration());
      expect(await ref.watch(b), 2);
    });
  });

  group('dispose', () {
    test('dispose', () {
      final ref = RefForTest();
      final a = Creator.value(1);
      final b = Creator(((ref) => ref.watch(a) * 2));
      final c = Creator(((ref) => ref.watch(b) * 2));

      expect(ref.watch(c), 4);
      ref.dispose(b);
      expect(ref.elements.keys, {a, b, c});
      ref.dispose(c);
      expectEmpty(ref);
    });
  });

  group('disposeAll', () {
    test('test name', () {
      final ref = RefForTest();
      final a = Creator.value(1);
      final b = Creator(((ref) => ref.watch(a) * 2));
      final c = Creator(((ref) => ref.watch(b) * 2));

      expect(ref.watch(c), 4);
      ref.disposeAll();
      expectEmpty(ref);
    });
  });

  group('onClean', () {
    test('onClean is called for creator', () {
      final ref = RefForTest();
      final onClean = [];
      final a = Creator(((ref) {
        ref.onClean(() => onClean.add(1));
        return 1;
      }));

      expect(ref.watch(a), 1);
      expect(onClean, []);
      ref.recreate(a);
      expect(onClean, [1]);
      ref.dispose(a);
      expect(onClean, [1, 1]);
    });

    test('onClean is called for emitter', () async {
      final ref = RefForTest();
      final onClean = [];
      final a = Emitter<int>(((ref, emit) {
        ref.onClean(() => onClean.add(1));
        emit(1);
      }));

      expect(await ref.watch(a), 1);
      expect(onClean, []);
      ref.recreate(a);
      await Future.delayed(const Duration());
      expect(onClean, [1]);
      ref.dispose(a);
      expect(onClean, [1, 1]);
    });
  });

  group('creator equality', () {
    test('creator changes defined as local variable', () {
      final ref = RefForTest();
      final a = Creator.value(1, name: 'a');
      final c = Creator(((ref) {
        final b = Creator(((ref) => ref.watch(a) * 2), name: 'b');
        return ref.watch(b) * 2;
      }), name: 'c');

      expect(ref.watch(c), 4);
      final creators = {...ref.elements.keys};
      ref.recreate(c);

      expect(creators.length, ref.elements.length);
      expect(ref.elements.keys, contains(a));
      expect(ref.elements.keys, contains(c));
      expect(creators, contains(a));
      expect(creators, contains(c));
      expect(creators, isNot(ref.elements.keys));
    });

    test('creator do not change defined as local variable with args', () {
      final ref = RefForTest();
      final a = Creator.value(1);
      final c = Creator(((ref) {
        final b = Creator(((ref) => ref.watch(a) * 2), args: ['b']);
        return ref.watch(b) * 2;
      }));

      expect(ref.watch(c), 4);
      final creators = {...ref.elements.keys};
      ref.recreate(c);

      expect(ref.elements.keys, contains(a));
      expect(ref.elements.keys, contains(c));
      expect(creators, contains(a));
      expect(creators, contains(c));
      expect(creators, ref.elements.keys);
    });
  });

  group('error handling', () {
    test('error in creator', () {
      final ref = RefForTest();
      final a = Creator.value('1');
      final b = Creator(((ref) => int.parse(ref.watch(a))));
      final c = Creator(((ref) => ref.watch(b) * 2));

      expect(ref.watch(b), 1);
      expect(ref.watch(c), 2);
      ref.set(a, 'invalid');
      expect(() => ref.watch(b), throwsFormatException);
      expect(() => ref.watch(c), throwsFormatException);
    });

    test('error in creator in initial state', () {
      final ref = RefForTest();
      final a = Creator.value('invalid');
      final b = Creator(((ref) => int.parse(ref.watch(a))));
      final c = Creator(((ref) => ref.watch(b) * 2));

      expect(() => ref.watch(b), throwsFormatException);
      expect(() => ref.watch(c), throwsFormatException);
      ref.set(a, '1');
      expect(ref.watch(b), 1);
      expect(ref.watch(c), 2);
    });

    test('error in emitter', () async {
      final ref = RefForTest();
      final a =
          Emitter<String>((ref, emit) async => emit(await Future.value('1')));
      final b = Emitter<int>(
          ((ref, emit) async => emit(int.parse(await ref.watch(a)))));
      final c =
          Emitter<int>(((ref, emit) async => emit(await ref.watch(b) * 2)));

      expect(await ref.watch(b), 1);
      expect(await ref.watch(c), 2);
      ref.set(a, Future.value('invalid'));
      await Future.delayed(const Duration());
      expect(() async => await ref.watch(b), throwsFormatException);
      expect(() async => await ref.watch(c), throwsFormatException);
    });
  });

  group('change', () {
    test('change for creator', () {
      final ref = RefForTest();
      final creator = Creator.value(1);

      expect(ref.watch(creator.change), Change(null, 1));
      ref.set(creator, 2);
      expect(ref.watch(creator.change), Change(1, 2));
    });

    test('change for emitter', () async {
      final ref = RefForTest();
      final creator = Creator.value(1);
      final emitter = Emitter<int>(
          (ref, emit) async => emit(await Future.value(ref.watch(creator))));

      expect(await ref.watch(emitter.change), Change(null, 1));
      ref.set(creator, 2);
      await Future.delayed(const Duration());
      expect(await ref.watch(emitter.change), Change(1, 2));
    });
  });

  group('asyncData', () {
    test('asyncData', () async {
      final ref = RefForTest();
      final creator = Creator.value(1);
      final emitter = Emitter<int>(
          (ref, emit) async => emit(await Future.value(ref.watch(creator))));

      expect(ref.watch(emitter.asyncData), AsyncData.waiting());
      await Future.delayed(const Duration(microseconds: 100));
      expect(ref.watch(emitter.asyncData), AsyncData.withData(1));
      ref.set(creator, 2);
      await Future.delayed(const Duration());
      expect(ref.watch(emitter.asyncData), AsyncData.withData(2));
    });
  });
}
