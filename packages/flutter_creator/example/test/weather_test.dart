// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:example/weather.dart';
import 'package:flutter_creator/flutter_creator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('temperature creator change unit', () async {
    final ref = Ref();
    expect(await ref.watch(temperatureCreator), "60 F");
    ref.set(unitCreator, 'Celsius');
    await Future.delayed(const Duration()); // allow emitter to propagate
    expect(await ref.watch(temperatureCreator), "16 C");
  });
  test('temperature creator change fahrenheit value', () async {
    final ref = Ref();
    expect(await ref.watch(temperatureCreator), "60 F");
    ref.set(fahrenheitCreator, Future.value(90));
    await Future.delayed(const Duration()); // allow emitter to propagate
    expect(await ref.watch(temperatureCreator), "90 F");
  });
}
