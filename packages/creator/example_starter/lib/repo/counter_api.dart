import 'counter_model.dart';

/// Fetch the user's counter from server. Fake the logic for now.
Future<Counter> fetchCounter(String userId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return const Counter(42);
}
