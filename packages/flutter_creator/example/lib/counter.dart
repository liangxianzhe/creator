import 'package:flutter/material.dart';
import 'package:flutter_creator/flutter_creator.dart';

// A counter app shows basic Creator/Watcher usage.

// Creator creates a stream of data.
final counter = Creator.value(0);

void main() {
  // Wrap the app with a creator graph.
  runApp(CreatorGraph(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Counter example')),
        body: Center(
          // Watcher will rebuild whenever counter changes.
          child: Watcher((context, ref, _) {
            return Text('${ref.watch(counter)}');
          }),
        ),
        floatingActionButton: FloatingActionButton(
          // Update state is easy.
          onPressed: () =>
              context.ref.update<int>(counter, (count) => count + 1),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
