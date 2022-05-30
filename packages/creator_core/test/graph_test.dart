import 'package:creator_core/src/graph.dart';
import 'package:test/test.dart';

void main() {
  test('add edge', () {
    final graph = Graph<int>();

    graph.addEdge(1, 2);
    expect(graph.from(1), {2});
    expect(graph.to(2), {1});

    graph.addEdge(2, 3);
    expect(graph.from(2), {3});
    expect(graph.to(3), {2});

    graph.addEdge(1, 3);
    expect(graph.from(1), {2, 3});
    expect(graph.to(2), {1});
    expect(graph.to(3), {1, 2});

    graph.addEdge(1, 3); // Exist edge
    expect(graph.from(1), {2, 3});
    expect(graph.to(2), {1});
    expect(graph.to(3), {1, 2});
  });

  group('delete edge', () {
    test('not exist', () {
      final graph = Graph<int>();
      expect(graph.deleteEdge(1, 2), []);
      graph.addEdge(2, 3);
      expect(graph.deleteEdge(1, 2), []);
    });
    test('single node', () {
      final graph = Graph<int>()
        ..addEdge(1, 2)
        ..addEdge(2, 3)
        ..addEdge(3, 4);
      expect(graph.deleteEdge(1, 2), [1]);
      expect(graph.deleteEdge(2, 3), [2]);
      expect(graph.deleteEdge(3, 4), [3]);
    });
    test('zero out degree', () {
      final graph = Graph<int>()
        ..addEdge(1, 2)
        ..addEdge(2, 3)
        ..addEdge(3, 4);
      expect(graph.deleteEdge(3, 4), [3, 2, 1]);
    });
    test('non zero out degree', () {
      final graph = Graph<int>()
        ..addEdge(1, 4)
        ..addEdge(2, 4)
        ..addEdge(3, 4);
      expect(graph.deleteEdge(1, 4), [1]);
      expect(graph.deleteEdge(2, 4), [2]);
      expect(graph.deleteEdge(3, 4), [3]);
    });
    test('keep alive', () {
      final graph = Graph<int>(keepAlive: (n) => n == 3)
        ..addEdge(1, 2)
        ..addEdge(2, 3)
        ..addEdge(3, 4);
      expect(graph.deleteEdge(3, 4), []);
    });
    test('dependency keep alive', () {
      final graph = Graph<int>(keepAlive: (n) => n == 2)
        ..addEdge(1, 2)
        ..addEdge(2, 3)
        ..addEdge(3, 4);
      expect(graph.deleteEdge(3, 4), [3]);
    });
  });
  group('delete node', () {
    test('not exist', () {
      final graph = Graph<int>();
      expect(graph.delete(1), []);
      graph.addEdge(2, 3);
      expect(graph.delete(1), []);
    });
    test('zero out degree', () {
      final graph = Graph<int>()
        ..addEdge(1, 2)
        ..addEdge(2, 3)
        ..addEdge(3, 4);
      expect(graph.delete(4), [4, 3, 2, 1]);
    });
    test('non zero out degree', () {
      final graph = Graph<int>()
        ..addEdge(1, 2)
        ..addEdge(2, 3)
        ..addEdge(3, 4);
      expect(graph.delete(3), [3, 2, 1]);
    });
    test('keep alive', () {
      final graph = Graph<int>(keepAlive: (n) => n == 4)
        ..addEdge(1, 2)
        ..addEdge(2, 3)
        ..addEdge(3, 4);
      expect(graph.delete(4), [4, 3, 2, 1]);
    });
    test('dependency keep alive', () {
      final graph = Graph<int>(keepAlive: (n) => n == 2)
        ..addEdge(1, 2)
        ..addEdge(2, 3)
        ..addEdge(3, 4);
      expect(graph.delete(4), [4, 3]);
    });
  });
  test('to string', () {
    final graph = Graph<String>()..addEdge('foo', 'bar');
    expect(graph.toString(), stringContainsInOrder(['foo', 'bar']));
    expect(graph.toDebugString(),
        stringContainsInOrder(['Out', 'foo', 'bar', 'In', 'bar', 'foo']));
  });
}
