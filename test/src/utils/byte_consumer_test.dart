import 'package:test/test.dart';
import 'package:xterm/src/utils/byte_consumer.dart';

List<int> consumeAll(ByteConsumer consumer) {
  final result = <int>[];
  while (consumer.isNotEmpty) {
    result.add(consumer.consume());
  }
  return result;
}

void main() {
  group('ByteConsumer.add', () {
    test('yields the same code points as String.runes for ascii', () {
      const data = 'Hello, World!\x1b[31m';
      final consumer = ByteConsumer()..add(data);

      expect(consumeAll(consumer), equals(data.runes.toList()));
    });

    test('combines surrogate pairs like String.runes', () {
      const data = 'a😀b😁c';
      final consumer = ByteConsumer()..add(data);

      expect(consumeAll(consumer), equals(data.runes.toList()));
      expect(data.runes.length, equals(5));
    });

    test('passes lone surrogates through like String.runes', () {
      final data = 'a\uD800b\uDC00c';
      final consumer = ByteConsumer()..add(data);

      expect(consumeAll(consumer), equals(data.runes.toList()));
    });

    test('supports rollback across added blocks', () {
      final consumer = ByteConsumer()
        ..add('ab')
        ..add('😀d');

      final first = consumeAll(consumer);
      consumer.rollback(first.length);

      expect(consumeAll(consumer), equals(first));
    });
  });
}
