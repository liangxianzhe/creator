import 'package:creator/creator.dart';

/// Get user id of the current login user.
final userCreator = Emitter<String?>((ref, emit) async {
  await Future.delayed(const Duration(milliseconds: 100));
  // Depends on how you store user's session, fetch the session data.
  // Here let's assume there is no login user.
  emit(null);
}, name: 'user', keepAlive: true);

/// Login a user using email and password. Change to whatever login method you
/// use.
void login(Ref ref, String email, String password) async {
  await Future.delayed(const Duration(milliseconds: 100));
  ref.emit(userCreator, 'user_$email');
}

/// To use Firebase Auth:
/// 1. Set up Firebase project following its official guide.
///    https://firebase.google.com/docs/auth/flutter/start
/// 2. Uncomment and switch to the below methods.

// /// Get user id of the current login user. You can return the firebase user
// /// object rather than the user id if you want.
// final userCreator =
//     Emitter.stream((ref) => FirebaseAuth.instance.authStateChanges()).map(
//   (firebaseUser) => firebaseUser?.uid,
//   name: 'user',
//   keepAlive: true,
// );

// /// Login a user using email and password. Change to whatever login method
// /// you use.
// void login(Ref ref, String email, String password) async {
//   FirebaseAuth.instance
//       .signInWithEmailAndPassword(email: email, password: password);
// }
