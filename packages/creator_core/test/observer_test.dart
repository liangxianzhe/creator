import 'package:creator_core/src/core.dart';
import 'package:creator_core/src/observer.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'observer_test.mocks.dart';

@GenerateMocks([DefaultCreatorObserver])
void main() {
  test('ignore creators', () {
    final ob = DefaultCreatorObserver();
    expect(ob.ignore(Creator.value(42, name: 'foo')), false);
    expect(ob.ignore(Creator.value(42, name: 'foo_asyncData')), true);
    expect(ob.ignore(Creator.value(42, name: 'foo_change')), true);
  });

  test('observer is called for creator', () {
    final ob = MockDefaultCreatorObserver();
    final ref = Ref(observer: ob);
    final creator = Creator.value(1);

    verifyZeroInteractions(ob);
    ref.watch(creator);
    ref.set(creator, 2);
    ref.set(creator, 3);
    verifyInOrder([
      ob.onStateChange(creator, null, 1),
      ob.onStateChange(creator, 1, 2),
      ob.onStateChange(creator, 2, 3),
    ]);
  });

  test('observer is called for emitter', () async {
    final ob = MockDefaultCreatorObserver();
    final ref = Ref(observer: ob);
    final value = [1, 2, 3];
    final creator = Emitter<int>(
        (ref, emit) async => emit(await Future.value(value.removeAt(0))));

    verifyZeroInteractions(ob);
    await ref.watch(creator);
    ref.recreate(creator);
    await Future.value();
    ref.recreate(creator);
    await Future.value();
    verifyInOrder([
      ob.onStateChange(creator, null, 1),
      ob.onStateChange(creator, 1, 2),
      ob.onStateChange(creator, 2, 3),
    ]);
  });
}
