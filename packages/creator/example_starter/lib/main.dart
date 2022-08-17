import 'package:creator/creator.dart';
import 'package:flutter/material.dart';

import 'route.dart';

void main() async {
  /// Wrap your app with CreatorGraph, where state graph is stored.
  runApp(CreatorGraph(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final router = context.ref.watch(goRouter);
    return MaterialApp.router(
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      debugShowCheckedModeBanner: false,
      title: 'My Fancy App',
    );
  }
}
