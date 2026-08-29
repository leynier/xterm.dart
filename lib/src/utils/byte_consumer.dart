import 'dart:collection';
import 'dart:typed_data';

class ByteConsumer {
  final _queue = ListQueue<List<int>>();

  final _consumed = ListQueue<List<int>>();

  var _currentOffset = 0;

  var _length = 0;

  var _totalConsumed = 0;

  void add(String data) {
    if (data.isEmpty) return;
    // Decode code points into a preallocated block instead of materializing
    // `data.runes.toList()`, which grows a boxed list per chunk on the UI
    // isolate. Semantics match [Runes]: valid surrogate pairs combine, and a
    // lone surrogate yields its own code unit.
    final units = Uint32List(data.length);
    var count = 0;
    for (var i = 0; i < data.length; i++) {
      var unit = data.codeUnitAt(i);
      if (unit >= 0xD800 && unit <= 0xDBFF && i + 1 < data.length) {
        final next = data.codeUnitAt(i + 1);
        if (next >= 0xDC00 && next <= 0xDFFF) {
          unit = 0x10000 + ((unit - 0xD800) << 10) + (next - 0xDC00);
          i++;
        }
      }
      units[count++] = unit;
    }
    // A view avoids a second copy; the backing block is short-lived because
    // consumed blocks are unreferenced after each parse pass.
    final block =
        count == data.length ? units : Uint32List.sublistView(units, 0, count);
    _queue.addLast(block);
    _length += count;
  }

  int peek() {
    final data = _queue.first;
    if (_currentOffset < data.length) {
      return data[_currentOffset];
    } else {
      final result = consume();
      rollback();
      return result;
    }
  }

  int consume() {
    final data = _queue.first;

    if (_currentOffset >= data.length) {
      _consumed.add(_queue.removeFirst());
      _currentOffset -= data.length;
      return consume();
    }

    _length--;
    _totalConsumed++;
    return data[_currentOffset++];
  }

  /// Rolls back the last [n] call.
  void rollback([int n = 1]) {
    _currentOffset -= n;
    _totalConsumed -= n;
    _length += n;
    while (_currentOffset < 0) {
      final rollback = _consumed.removeLast();
      _queue.addFirst(rollback);
      _currentOffset += rollback.length;
    }
  }

  /// Rolls back to the state when this consumer had [length] bytes.
  void rollbackTo(int length) {
    rollback(length - _length);
  }

  int get length => _length;

  int get totalConsumed => _totalConsumed;

  bool get isEmpty => _length == 0;

  bool get isNotEmpty => _length != 0;

  /// Unreferences data blocks that have been consumed. After calling this
  /// method, the consumer will not be able to roll back to consumed blocks.
  void unrefConsumedBlocks() {
    _consumed.clear();
  }

  /// Resets the consumer to its initial state.
  void reset() {
    _queue.clear();
    _consumed.clear();
    _currentOffset = 0;
    _totalConsumed = 0;
    _length = 0;
  }
}

// void main() {
//   final consumer = ByteConsumer();
//   consumer.add(Uint8List.fromList([1, 2, 3]));
//   consumer.add(Uint8List.fromList([4, 5, 6]));

//   while (consumer.isNotEmpty) {
//     print(consumer.consume());
//   }

//   consumer.rollback(5);

//   while (consumer.isNotEmpty) {
//     print(consumer.consume());
//   }

//   consumer.rollbackTo(3);

//   while (consumer.isNotEmpty) {
//     print(consumer.consume());
//   }
// }
