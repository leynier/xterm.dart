import 'package:test/test.dart';
import 'package:xterm/src/core/input/keytab/keytab.dart';
import 'package:xterm/xterm.dart';

void main() {
  group('defaultInputHandler', () {
    test('supports numpad enter', () {
      final output = <String>[];
      final terminal = Terminal(onOutput: output.add);
      terminal.keyInput(TerminalKey.numpadEnter);
      expect(output, ['\r']);
    });

    test('supports enter', () {
      final output = <String>[];
      final terminal = Terminal(onOutput: output.add);
      terminal.keyInput(TerminalKey.enter);
      expect(output, ['\r']);
    });

    test('preserves shift enter as csi-u', () {
      final output = <String>[];
      final terminal = Terminal(onOutput: output.add);
      terminal.keyInput(TerminalKey.enter, shift: true);
      terminal.keyInput(TerminalKey.returnKey, shift: true);
      expect(output, ['\x1b[13;2u', '\x1b[13;2u']);
    });
  });

  group('KeytabInputHandler', () {
    test('can insert modifier code', () {
      final handler = KeytabInputHandler(
        Keytab.parse(r'key Home +AnyMod : "\E[1;*H"'),
      );

      final terminal = Terminal(inputHandler: handler);

      late String output;

      terminal.onOutput = (data) {
        output = data;
      };

      terminal.keyInput(TerminalKey.home, ctrl: true);

      expect(output, '\x1b[1;5H');

      terminal.keyInput(TerminalKey.home, shift: true);

      expect(output, '\x1b[1;2H');
    });
  });
}
