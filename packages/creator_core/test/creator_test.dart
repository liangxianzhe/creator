import 'dart:async';

import 'package:creator_core/src/core.dart';
import 'package:test/test.dart';

void main() {
  group('creator base', () {
    test('equality', () {
      expect(Creator.value(42), isNot(Creator.value(42)));
      expect(Creator.value(42, args: [1]), isNot(Creator.value(42)));
      expect(Creator.value(42, args: [1, 'f']),
          isNot(Creator.value(42, args: [1])));

      final creator = Creator.value(42);
      expect(creator, creator);
      expect(
          Creator.value(42, args: [1, 'f']), Creator.value(99, args: [1, 'f']));
    });

    test('hash code', () {
      expect(Creator.value(42).hashCode, isNot(Creator.value(42).hashCode));
      expect(Creator.value(42, args: [1]).hashCode,
          isNot(Creator.value(42).hashCode));
      expect(Creator.value(42, args: [1, 'f']).hashCode,
          isNot(Creator.value(42, args: [1]).hashCode));

      final creator = Creator.value(42);
      expect(creator.hashCode, creator.hashCode);
      expect(Creator.value(42, args: [1, 'f']).hashCode,
          Creator.value(99, args: [1, 'f']).hashCode);
    });

    test('name set', () {
      final creator = Creator.value(42, name: 'foo');
      expect(creator.name, 'foo');
      expect(creator.infoName, 'foo');
      expect(creator.debugName, startsWith('foo'));
      expect(creator.debugName.length, 10); // foo(xxxxx)
    });

    test('name not set', () {
      final creator = Creator.value(42);
      expect(creator.name, null);
      expect(creator.infoName.length, 5); // xxxxx
      expect(creator.debugName.length, 7); // (xxxxx)
    });
  });

  group('creator', () {
    test('constructor', () {
      final c =
          Creator((ref) => 42, name: 'foo', keepAlive: true, args: [1, 2]);
      expect(c.name, 'foo');
      expect(c.keepAlive, true);
      expect(c.args, [1, 2]);
    });

    test('value constructor', () {
      final c = Creator.value(42, name: 'foo', keepAlive: true, args: [1, 2]);
      expect(c.name, 'foo');
      expect(c.keepAlive, true);
      expect(c.args, [1, 2]);
    });
  });

  group('creator element', () {
    test('recreate', () {
      final states = [1, 2];
      final creator = Creator((ref) => states.removeAt(0));
      final element = CreatorElement(RefForLifeCycleTest(creator), creator)
        ..recreate(); // Ref calls recreate when construct element.
      expect(element.state, 1);
      expect(element.prevState, null);

      element.recreate();
      expect(element.state, 2);
      expect(element.prevState, 1);
    });
  });

  group('emitter', () {
    test('constructor', () {
      final c = Emitter<int>((ref, emit) => emit(42),
          name: 'foo', keepAlive: true, args: [1, 2]);
      expect(c.name, 'foo');
      expect(c.keepAlive, true);
      expect(c.args, [1, 2]);
    });

    test('stream constructor sync', () {
      final stream = Stream.fromIterable([1, 2]);
      final c = Emitter.stream((ref) => stream,
          name: 'foo', keepAlive: true, args: [1, 2]);
      expect(c.name, 'foo');
      expect(c.keepAlive, true);
      expect(c.args, [1, 2]);
    });

    test('stream constructor async', () {
      final stream = Stream.fromIterable([1, 2]);
      final c = Emitter.stream((ref) async => Future.value(stream),
          name: 'foo', keepAlive: true, args: [1, 2]);
      expect(c.name, 'foo');
      expect(c.keepAlive, true);
      expect(c.args, [1, 2]);
    });
  });

  group('emitter element', () {
    test('recreate sync', () {
      final states = [1, 2];
      final creator = Emitter<int>((ref, emit) => emit(states.removeAt(0)));
      final completer = Completer();
      final element =
          EmitterElement(RefForLifeCycleTest(creator), creator, completer);
      expect(element.value, null);
      expect(element.prevValue, null);
      expect(element.state, completer.future);
      expect(element.state, completion(1));
      expect(element.prevState, null);

      element.recreate();
      expect(element.value, 1);
      expect(element.prevValue, null);
      expect(element.state, completer.future);
      expect(element.state, completion(1));
      expect(element.prevState, null);

      element.recreate();
      expect(element.value, 2);
      expect(element.prevValue, 1);
      expect(element.state, isNot(completer.future));
      expect(element.state, completion(2));
      expect(element.prevState, completer.future);
      expect(element.prevState, completion(1));
    });

    test('recreate async', () async {
      final states = [1, 2];
      final creator = Emitter<int>(
          (ref, emit) async => emit(await Future.value(states.removeAt(0))));
      final completer = Completer();
      final element =
          EmitterElement(RefForLifeCycleTest(creator), creator, completer);
      expect(element.value, null);
      expect(element.prevValue, null);
      expect(element.state, completer.future);
      expect(element.state, completion(1));
      expect(element.prevState, null);

      await element.recreate();
      expect(element.value, 1);
      expect(element.prevValue, null);
      expect(element.state, completer.future);
      expect(element.state, completion(1));
      expect(element.prevState, null);

      await element.recreate();
      expect(element.value, 2);
      expect(element.prevValue, 1);
      expect(element.state, isNot(completer.future));
      expect(element.state, completion(2));
      expect(element.prevState, completer.future);
      expect(element.prevState, completion(1));
    });

    test('recreate multiple emit', () async {
      final states = [1, 2, 3, 4];
      final creator = Emitter<int>((ref, emit) async {
        emit(await Future.value(states.removeAt(0)));
        emit(await Future.value(states.removeAt(0)));
      });
      final completer = Completer();
      final element =
          EmitterElement(RefForLifeCycleTest(creator), creator, completer);
      expect(element.value, null);
      expect(element.prevValue, null);
      expect(element.state, completer.future);
      expect(element.state, completion(1));
      expect(element.prevState, null);

      await element.recreate();
      expect(element.value, 2);
      expect(element.prevValue, 1);
      expect(element.state, isNot(completer.future));
      expect(element.state, completion(2));
      expect(element.prevState, completion(1));

      await element.recreate();
      expect(element.value, 4);
      expect(element.prevValue, 3);
      expect(element.state, isNot(completer.future));
      expect(element.state, completion(4));
      expect(element.prevState, completion(3));
    });
  });

  test('change', () {
    final c1 = Change(1, 2);
    final c2 = Change(1, 2);
    expect(c1, c2);
    expect(c1.hashCode, c2.hashCode);
    expect(c1.toString(), '1->2');
  });

  test('creator change is stable', () {
    final creator = Creator.value(42);
    final c1 = creator.change;
    final c2 = creator.change;
    expect(c1, c2);
    expect(c1.args, [creator, 'change']);
  });

  test('creator asyncData is stable', () {
    final creator = Emitter<int>((ref, emit) => emit(42));
    final c1 = creator.asyncData;
    final c2 = creator.asyncData;
    expect(c1, c2);
    expect(c1.args, [creator, 'asyncData']);
  });
}
