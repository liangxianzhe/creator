enum AsyncDataStatus { waiting, active }

/// AsyncData is either in waiting state, or in active state with data.
class AsyncData<T> {
  const AsyncData._(this.status, this.data);

  const AsyncData.waiting() : this._(AsyncDataStatus.waiting, null);
  const AsyncData.withData(T data) : this._(AsyncDataStatus.active, data);

  final AsyncDataStatus status;
  final T? data;

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) => other is AsyncData<T> && data == other.data;

  @override
  String toString() =>
      status == AsyncDataStatus.waiting ? 'waiting' : 'active($data)';
}
