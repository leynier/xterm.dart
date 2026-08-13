import 'package:test/test.dart';
import 'package:xterm/xterm.dart';

void main() {
  group('cursor restore after resize at buffer capacity', () {
    test('preserves pending wrap when restoring at the right margin', () {
      final terminal = Terminal(reflowEnabled: false)
        ..resize(4, 2)
        ..write('abcd\x1b7\x1b8x');

      expect(terminal.buffer.lines[0].toString(), 'abcd');
      expect(terminal.buffer.lines[1].toString(), 'x');
    });

    test('preserves saved coordinates across a temporary shrink', () {
      final terminal = Terminal(maxLines: 100, reflowEnabled: false)
        ..resize(8, 5)
        ..write('\x1b[5;7H\x1b7')
        ..resize(4, 3)
        ..resize(8, 5)
        ..write('\x1b8');

      expect(terminal.buffer.cursorX, 6);
      expect(terminal.buffer.cursorY, 4);
    });

    test('keeps writeChar on the retained viewport', () {
      final terminal = _terminalWithCursorRestoredAfterResize();

      expect(() => terminal.write('x'), returnsNormally);
      expect(
        terminal.buffer.lines[terminal.buffer.lines.length - 1].toString(),
        'x',
      );
    });

    test('keeps eraseLineRight on the retained viewport', () {
      final terminal = _terminalWithCursorRestoredAfterResize(
        lastLineText: 'stale',
      );

      expect(() => terminal.write('\x1b[K'), returnsNormally);
      expect(
        terminal.buffer.lines[terminal.buffer.lines.length - 1].toString(),
        isEmpty,
      );
    });
  });
}

Terminal _terminalWithCursorRestoredAfterResize({String lastLineText = ''}) {
  final terminal = Terminal(maxLines: 5000, reflowEnabled: false)
    ..resize(8, 5)
    ..write('\x1b[5;1H\x1b7')
    ..resize(8, 3);

  for (var i = 0; i < 5000; i++) {
    terminal.write('\r\n');
  }
  terminal
    ..write(lastLineText)
    ..write('\x1b8');

  expect(terminal.buffer.lines, hasLength(5000));
  return terminal;
}
