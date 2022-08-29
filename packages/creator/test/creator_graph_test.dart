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

    test('not raising error', () {
      final ob = DefaultCreatorObserver();
      final creator = Creator.value(42);
      ob.onStateChange(creator, 1, 2);
      ob.onError(creator, 'error', null);
    });
  });
}
