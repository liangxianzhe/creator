/// Graph is a simple implementation of a bi-directed graph using adjacency
/// list. It can automatically delete nodes which become zero out-degree.
class Graph<T> {
  Graph({this.name, this.keepAlive});

  /// Get name from the node.
  final String Function(T)? name;
  String _name(T node) => name != null ? name!(node) : node.toString();

  /// Get keep alive property from the node.
  final bool Function(T)? keepAlive;
  bool _keepAlive(T node) => keepAlive != null ? keepAlive!(node) : false;

  /// Graph edges in normal direction. A : {B, C} means A -> B, A -> C.
  final Map<T, Set<T>> _out = {};

  /// Graph edges in reversed direction. D : {A, B} means A -> D, B -> D.
  final Map<T, Set<T>> _in = {};

  /// Get all nodes from a node.
  Set<T> from(T node) => _out[node] ?? {};

  /// Get all nodes to a node.
  Set<T> to(T node) => _in[node] ?? {};

  /// Return whether a node is in the graph.
  bool contains(T node) => _out.containsKey(node) || _in.containsKey(node);

  /// Get all nodes. Used for testing only.
  Set<T> get nodes => {..._out.keys, ..._in.keys};

  /// Add an edge.
  void addEdge(T from, T to) {
    _out[from] ??= {};
    _out[from]!.add(to);
    _in[to] ??= {};
    _in[to]!.add(from);
  }

  /// Remove an edge and non-keep-alive nodes which become zero out-degree.
  /// Return deleted nodes.
  List<T> deleteEdge(T from, T to) {
    _out[from]?.remove(to);
    _in[to]?.remove(from);
    return _keepAlive(from) || this.from(from).isNotEmpty ? [] : delete(from);
  }

  /// Delete a node and other non-keep-alive nodes which become zero out-degree,
  /// using BFS. Return deleted nodes.
  List<T> delete(T node) {
    if (!contains(node)) {
      return [];
    }
    var toCheck = [node];
    final deleted = <T>[];
    while (toCheck.isNotEmpty) {
      final n = toCheck.first;
      toCheck = toCheck.sublist(1);
      if (n == node || (!_keepAlive(n) && from(n).isEmpty)) {
        toCheck.addAll(_in[n] ?? []);
        _delete(n);
        deleted.add(n);
      }
    }
    return deleted;
  }

  /// Perform the actual delete.
  void _delete(T node) {
    _out[node]?.forEach((n) => _in[n]!.remove(node));
    _out.remove(node);
    _in[node]?.forEach((n) => _out[n]!.remove(node));
    _in.remove(node);
  }

  @override
  String toString() {
    return _out.entries
        .map((e) => '- ${_name(e.key)}: {${e.value.map(_name).join(', ')}}')
        .join('\n');
  }

  String toDebugString() {
    return [
      '- Out:',
      ..._out.entries.map(
          (e) => '  - ${_name(e.key)}: {${e.value.map(_name).join(', ')}}'),
      '- In:',
      ..._in.entries.map(
          (e) => '  - ${_name(e.key)}: {${e.value.map(_name).join(', ')}}'),
    ].join('\n');
  }
}
