import 'dart:math';

import 'package:creator/creator.dart';
import 'package:example_starter/logic/auth_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    "test user creator",
    () async {
      final ref = Ref();
      expect(await ref.watch(userCreator), null);

      login(ref, 'hello', 'world');
      await Future.delayed(const Duration(milliseconds: 200));
      expect(await ref.watch(userCreator), 'user_hello');
    },
  );
}
