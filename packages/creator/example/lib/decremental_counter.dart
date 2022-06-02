import 'package:flutter/material.dart';
import 'package:creator/creator.dart';

// A counter app shows how to expose state mutate APIs. Simple and no magic.

// counter_logic.dart

// Hide the creator with file level private variable.
final _counter = Creator.value(0);

// Expose the state related APIs.
int counter(Ref ref) => ref.watch(_counter);
void increment(Ref ref) => ref.update<int>(_counter, (n) => n + 1);
void decrement(Ref ref) => ref.update<int>(_counter, (n) => n - 1);

// main.dart

void main() {
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Watcher((context, ref, _) {
                return Text('${counter(ref)}');
              }),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => increment(context.ref),
                    child: const Text('+1'),
                  ),
                  TextButton(
                    onPressed: () => decrement(context.ref),
                    child: const Text('-1'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
