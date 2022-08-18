import 'package:creator/creator.dart';
import 'package:example_starter/logic/counter_logic.dart';
import 'package:flutter/material.dart';

class CounterView extends StatelessWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Watcher((context, ref, _) {
      final counter = ref.watch(counterCreator.asyncData).data;
      if (counter == null) {
        return const CircularProgressIndicator();
      }
      return Text('Counter: ${counter.count}');
    });
  }
}
