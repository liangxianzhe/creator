import 'package:creator_core/creator_core.dart';

final number = Creator.value(1);
final double = number.map(((n) => n * 2));
final triple = Emitter<int>(
  (ref, emit) {
    emit(ref.watch(number) * 3);
  },
);

Future<void> main(List<String> args) async {
  final ref = Ref();

  print(ref.watch(double)); // 2
  print(await ref.watch(triple)); // 3

  ref.set(number, 10);
  await Future.delayed(const Duration());
  print(ref.watch(double)); // 20
  print(await ref.watch(triple)); // 30
}
