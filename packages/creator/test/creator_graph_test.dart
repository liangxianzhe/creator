import 'package:flutter/material.dart';
import 'package:creator/creator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('creator graph', () {
    testWidgets('creator graph expose ref', (tester) async {
      late Ref contextRef;
      final creator = Creator.value(42);
      final creatorGraph = CreatorGraph(child: MaterialApp(
        home: Watcher(((context, ref, child) {
          contextRef = context.ref;
          return Text('${ref.watch(creator)}');
        })),
      ));
      await tester.pumpWidget(creatorGraph);
      expect(find.text('42'), findsOneWidget);
      expect(contextRef, creatorGraph.ref);
    });

    testWidgets('creator graph dispose ref', (tester) async {
      final dispose = [];
      final creator = Creator((ref) {
        ref.onClean(() => dispose.add(1));
        return 42;
      });
      final creatorGraph = CreatorGraph(child: MaterialApp(
        home: Watcher(((context, ref, child) {
          return Text('${ref.watch(creator)}');
        })),
      ));
      await tester.pumpWidget(creatorGraph);
      await tester.pumpWidget(Container());
      expect(dispose, [1]);
    });
  });

  group('default observer', () {
    test('ignore creators', () {
      final ob = DefaultCreatorObserver();
      expect(ob.ignore(Creator.value(42, name: 'foo')), false);
      expect(ob.ignore(Creator.value(42, name: 'foo_asyncData')), true);
      expect(ob.ignore(Creator.value(42, name: 'foo_change')), true);
      expect(ob.ignore(Creator.value(42, name: 'watcher')), true);
      expect(ob.ignore(Creator.value(42, name: 'listener')), true);
    });

    test('ignore creators log watcher', () {
      final ob = DefaultCreatorObserver(logWatcher: true);
      expect(ob.ignore(Creator.value(42, name: 'watcher')), false);
      expect(ob.ignore(Creator.value(42, name: 'listener')), false);
    });

    test('ignore creators log derived', () {
      final ob = DefaultCreatorObserver(logDerived: true);
      expect(ob.ignore(Creator.value(42, name: 'foo_asyncData')), false);
      expect(ob.ignore(Creator.value(42, name: 'foo_change')), false);
    });

    test('not raising error on state change', () {
      final creator = Creator.value(42);
      DefaultCreatorObserver().onStateChange(creator, 1, 2);
      DefaultCreatorObserver(logStateChange: false)
          .onStateChange(creator, 1, 2);
      DefaultCreatorObserver(logState: false).onStateChange(creator, 1, 2);
    });

    test('not raising error on error', () {
      final creator = Creator.value(42);
      DefaultCreatorObserver().onError(creator, 'error', null);
      DefaultCreatorObserver(logError: false).onError(creator, 'error', null);
    });

    test('not raising error on dispose', () {
      final creator = Creator.value(42);
      DefaultCreatorObserver().onDispose(creator);
      DefaultCreatorObserver(logDispose: false).onDispose(creator);
    });
  });
}
