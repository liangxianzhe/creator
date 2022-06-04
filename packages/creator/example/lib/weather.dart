import 'package:flutter/material.dart';
import 'package:creator/creator.dart';

// Simple weather app shows splitting backend/logic/ui code, building logic
// with Creator (sync) and Emitter (async), and writing concise code with
// creator's extension methods.

// repo.dart

// Pretend calling a backend service to get fahrenheit temperature.
Future<int> getFahrenheit(String city) async {
  await Future.delayed(const Duration(milliseconds: 100));
  return 60 + city.hashCode % 20;
}

// logic.dart

// Simple creators bind to UI.
final cityCreator = Creator.value('London');
final unitCreator = Creator.value('Fahrenheit');

// Write fluid code with extensions like map, where, reduce, etc.
final fahrenheitCreator = cityCreator.asyncMap(getFahrenheit);

// Get temperature with data from backend and user's unit selection.
final temperatureCreator = Emitter<String>((ref, emit) async {
  final f = await ref.watch(fahrenheitCreator);
  final unit = ref.watch(unitCreator);
  emit(unit == 'Fahrenheit' ? '$f F' : '${f2c(f)} C');
});

// Fahrenheit to celsius converter.
int f2c(int f) => ((f - 32) * 5 / 9).round();

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
        appBar: AppBar(title: const Text('Weather example')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Watcher((context, ref, _) {
              // Calling asyncData converts Future<String> to AsyncData<String>.
              final temperature = ref.watch(temperatureCreator.asyncData).data;
              return temperature != null
                  ? Text(temperature)
                  : const CircularProgressIndicator();
            }),
            const SizedBox(height: 20),
            Watcher(
              (context, ref, _) {
                final city = ref.watch(cityCreator);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['London', 'Pairs', 'Rome']
                      .map((e) => TextButton(
                          style: TextButton.styleFrom(
                              backgroundColor: city == e ? Colors.lime : null),
                          onPressed: () => ref.set(cityCreator, e),
                          child: Text(e)))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            Watcher(
              (context, ref, _) {
                final unit = ref.watch(unitCreator);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['Fahrenheit', 'Celsius']
                      .map((e) => TextButton(
                          style: TextButton.styleFrom(
                              backgroundColor: unit == e ? Colors.lime : null),
                          onPressed: () => ref.set(unitCreator, e),
                          child: Text(e)))
                      .toList(),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
