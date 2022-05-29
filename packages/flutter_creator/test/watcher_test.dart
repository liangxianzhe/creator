import 'package:flutter/material.dart';
import 'package:flutter_creator/flutter_creator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('builder', () {
    testWidgets(
      'child is returned without builder',
      (WidgetTester tester) async {
        await tester
            .pumpWidget(CreatorGraph(child: Watcher(null, child: Container())));
        expect(find.byType(Container), findsOneWidget);
      },
    );

    testWidgets(
      'builder is called when build',
      (WidgetTester tester) async {
        final build = [];
        final widget = CreatorGraph(child: Watcher((context, ref, child) {
          build.add(1);
          return Container();
        }));
        await tester.pumpWidget(widget);
        expect(find.byType(Container), findsOneWidget);
        expect(build, [1]);
      },
    );

    testWidgets(
      'builder is called when dependency changes',
      (WidgetTester tester) async {
        final build = [];
        final creator = Creator.value(1);
        late Ref contextRef;
        final widget = CreatorGraph(child: MaterialApp(
          home: Watcher((context, ref, child) {
            contextRef = context.ref;
            build.add(1);
            return Text(ref.watch(creator).toString());
          }),
        ));
        await tester.pumpWidget(widget);
        expect(find.text('1'), findsOneWidget);
        expect(build, [1]);

        contextRef.set(creator, 1);
        await tester.pump();
        expect(find.text('1'), findsOneWidget);
        expect(build, [1]);

        contextRef.set(creator, 2);
        await tester.pump();
        expect(find.text('2'), findsOneWidget);
        expect(build, [1, 1]);
      },
    );

    testWidgets('builder is disposed when watcher is disposed', (tester) async {
      final dispose = [];
      final creator = Creator.value(1);
      final creatorGraph = CreatorGraph(child: MaterialApp(
        home: Watcher(((context, ref, child) {
          ref.onClean(() => dispose.add(1));
          return Text('${ref.watch(creator)}');
        })),
      ));
      await tester.pumpWidget(creatorGraph);
      await tester.pumpWidget(Container());
      expect(dispose, [1]);
    });
  });

  group('listener', () {
    testWidgets(
      'listener is called when dependency changes',
      (WidgetTester tester) async {
        final build = [];
        final creator = Creator.value(1);
        late Ref copyOfRef;
        final widget = CreatorGraph(
            child: MaterialApp(
          home: Watcher(null, listener: (ref) {
            copyOfRef = ref;
            build.add(1);
            ref.watch(creator);
          }, child: Container()),
        ));
        await tester.pumpWidget(widget);
        expect(build, [1]);

        copyOfRef.set(creator, 1);
        await tester.pump();
        expect(build, [1]);

        copyOfRef.set(creator, 2);
        await tester.pump();
        expect(build, [1, 1]);
      },
    );

    testWidgets('listener is disposed when watcher is disposed',
        (tester) async {
      final dispose = [];
      final creator = Creator.value(1);
      final creatorGraph = CreatorGraph(
        child: MaterialApp(
            home: Watcher(null, listener: (ref) {
          ref.onClean(() => dispose.add(1));
          ref.watch(creator);
        }, child: Container())),
      );
      await tester.pumpWidget(creatorGraph);
      await tester.pumpWidget(Container());
      expect(dispose, [1]);
    });
  });
}
