import 'package:creator/creator.dart';

import '../repo/counter_api.dart';
import '../repo/counter_model.dart';
import 'auth_logic.dart';

/// Provide the counter data to view layer.
final counterCreator = Emitter<Counter>((ref, emit) async {
  final userId = await ref.watch(userCreator);
  if (userId == null) {
    return;
  }
  emit(await fetchCounter(userId));
}, name: 'counter');
