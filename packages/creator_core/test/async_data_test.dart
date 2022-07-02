import 'package:creator_core/src/async_data.dart';
import 'package:test/test.dart';

class _Data {
  const _Data(this.data);
  final int data;
}

void main() {
  group('constructor', () {
    test('waiting', () {
      expect(AsyncData.waiting().status, AsyncDataStatus.waiting);
      expect(AsyncData.waiting().data, null);
    });
    test('active', () {
      expect(AsyncData.withData(42).status, AsyncDataStatus.active);
      expect(AsyncData.withData(42).data, 42);
      expect(AsyncData<int?>.withData(null).status, AsyncDataStatus.active);
      expect(AsyncData<int?>.withData(null).data, null);
    });
  });

  group('equality', (() {
    test('simple data', () {
      expect(AsyncData<int>.waiting(), AsyncData.waiting());
      expect(AsyncData<int>.waiting(), isNot(AsyncData.withData(42)));
      expect(AsyncData.withData(42), AsyncData.withData(42));
      expect(AsyncData.withData(42), isNot(AsyncData.withData(24)));
    });
    test('object data', () {
      expect(AsyncData.waiting(), isNot(AsyncData.withData(_Data(42))));
      expect(
          AsyncData.withData(_Data(42)), isNot(AsyncData.withData(_Data(42))));
    });
  }));

  group('hash code', (() {
    test('simple data', () {
      expect(AsyncData<int>.waiting().hashCode, AsyncData.waiting().hashCode);
      expect(AsyncData<int>.waiting().hashCode,
          isNot(AsyncData.withData(42).hashCode));
      expect(AsyncData.withData(42).hashCode, AsyncData.withData(42).hashCode);
      expect(AsyncData.withData(42).hashCode,
          isNot(AsyncData.withData(24).hashCode));
    });
    test('object data', () {
      expect(AsyncData.waiting().hashCode,
          isNot(AsyncData.withData(_Data(42)).hashCode));
      expect(AsyncData.withData(_Data(42)).hashCode,
          isNot(AsyncData.withData(_Data(42)).hashCode));
    });
  }));

  test('to string', () {
    expect(AsyncData<int>.waiting().toString(), 'waiting');
    expect(AsyncData.withData(42).toString(), '42');
  });
}
