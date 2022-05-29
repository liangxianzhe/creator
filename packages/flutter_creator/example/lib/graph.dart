// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_creator/flutter_creator.dart';

// Simple app shows how the creator framework build internal graph dynamically.

// logic.dart

// Four-layer creators A B C D. Creator sums creators in previous layer.
final A = Creator.value(1, name: 'A');
final B1 = Creator((ref) => ref.watch(A), name: 'B1');
final B2 = Creator((ref) => ref.watch(A), name: 'B2');
final C1 = Creator((ref) => ref.watch(B1) + ref.watch(B2), name: 'C1');
final C2 = Creator((ref) => ref.watch(B1) + ref.watch(B2), name: 'C2');
final C3 = Creator((ref) => ref.watch(B1) + ref.watch(B2), name: 'C3');
final D1 =
    Creator((ref) => ref.watch(C1) + ref.watch(C2) + ref.watch(C3), name: 'D1');
final D2 =
    Creator((ref) => ref.watch(C1) + ref.watch(C2) + ref.watch(C3), name: 'D2');
final D3 =
    Creator((ref) => ref.watch(C1) + ref.watch(C2) + ref.watch(C3), name: 'D3');
final D4 =
    Creator((ref) => ref.watch(C1) + ref.watch(C2) + ref.watch(C3), name: 'D4');

// main.dart

void main() {
  runApp(CreatorGraph(child: const MyApp()));
}

/// Node allow user to decide whether to watch [creator].
class Node extends StatefulWidget {
  const Node(
    this.creator,
    this.onChange, {
    Key? key,
  }) : super(key: key);

  final CreatorBase creator;
  final VoidCallback onChange;

  @override
  State<Node> createState() => _NodeState();
}

class _NodeState extends State<Node> {
  bool watching = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextButton(
          style: TextButton.styleFrom(
              backgroundColor: watching ? Colors.lime : null),
          onPressed: () {
            setState(() {
              watching = !watching;
            });
            widget.onChange();
          },
          child: (watching)
              ? Watcher(
                  (context, ref, _) => Text(
                      '${widget.creator.name!} (${ref.watch(widget.creator)})'),
                  builderName: '${widget.creator.name!}_watcher',
                )
              : Text(widget.creator.name!),
        ),
      ],
    );
  }
}

class Home extends StatefulWidget {
  const Home({
    required this.ref,
    Key? key,
  }) : super(key: key);
  final Ref ref;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String graph = '';

  void changed() {
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        graph = widget.ref.graphString();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text('Creator internal graph state:'),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(graph),
          ),
          const SizedBox(height: 100),
          const Text('Select which creator to watch:'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Node(A, changed),
                ],
              ),
              Column(
                children: [
                  Node(B1, changed),
                  Node(B2, changed),
                ],
              ),
              Column(
                children: [
                  Node(C1, changed),
                  Node(C2, changed),
                  Node(C3, changed),
                ],
              ),
              Column(
                children: [
                  Node(D1, changed),
                  Node(D2, changed),
                  Node(D3, changed),
                  Node(D4, changed),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Ref ref;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref = CreatorGraphData.of(context).ref;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Graph example')),
        body: Home(ref: ref),
      ),
    );
  }
}
