import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xterm/xterm.dart';

void main() {
  test('Can instantiate Terminal', () {
    final terminal = Terminal(maxLines: 10000);
    terminal.write('hello');
  });

  test('TerminalStyle resolves configured font weight', () {
    const defaultStyle = TerminalStyle();
    const style = TerminalStyle(fontWeight: 500);

    expect(defaultStyle.toTextStyle().fontWeight, FontWeight.normal);
    expect(defaultStyle.toTextStyle(bold: true).fontWeight, FontWeight.bold);
    expect(style.toTextStyle().fontWeight, FontWeight.w500);
    expect(style.toTextStyle(bold: true).fontWeight, FontWeight.w700);
  });
}
