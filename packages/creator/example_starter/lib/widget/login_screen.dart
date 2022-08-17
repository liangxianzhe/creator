import 'package:creator/creator.dart';
import 'package:example_starter/logic/auth_logic.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          // Here you want to add UI to allow user to enter information.
          onPressed: () => login(context.ref, 'email_foo', 'password_bar'),
          child: const Text('Login'),
        ),
      ),
    );
  }
}
