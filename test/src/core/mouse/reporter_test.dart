import 'package:test/test.dart';
import 'package:xterm/src/core/mouse/reporter.dart';
import 'package:xterm/xterm.dart';

void main() {
  group('MouseReporter', () {
    test('report() supports normal mode', () {
      final output = MouseReporter.report(
        TerminalMouseButton.left,
        TerminalMouseButtonState.down,
        CellOffset(0, 0),
        MouseReportMode.normal,
      );

      expect(output, equals('\x1B[M !!'));
    });

    test('report() supports utf mode', () {
      final output = MouseReporter.report(
        TerminalMouseButton.left,
        TerminalMouseButtonState.down,
        CellOffset(0, 0),
        MouseReportMode.utf,
      );

      expect(output, equals('\x1B[M !!'));
    });

    test('report() supports sgr mode', () {
      final output = MouseReporter.report(
        TerminalMouseButton.left,
        TerminalMouseButtonState.down,
        CellOffset(0, 0),
        MouseReportMode.sgr,
      );

      expect(output, equals('\x1B[<0;1;1M'));
    });

    test('report() uses canonical sgr wheel button ids', () {
      expect(
        MouseReporter.report(
          TerminalMouseButton.wheelUp,
          TerminalMouseButtonState.down,
          CellOffset(4, 5),
          MouseReportMode.sgr,
        ),
        equals('\x1B[<64;5;6M'),
      );
      expect(
        MouseReporter.report(
          TerminalMouseButton.wheelDown,
          TerminalMouseButtonState.down,
          CellOffset(4, 5),
          MouseReportMode.sgr,
        ),
        equals('\x1B[<65;5;6M'),
      );
    });

    test('report() encodes drag, move, and modifiers', () {
      expect(
        MouseReporter.report(
          TerminalMouseButton.left,
          TerminalMouseButtonState.down,
          CellOffset(2, 3),
          MouseReportMode.sgr,
          motion: true,
        ),
        equals('\x1B[<32;3;4M'),
      );
      expect(
        MouseReporter.report(
          TerminalMouseButton.none,
          TerminalMouseButtonState.down,
          CellOffset(2, 3),
          MouseReportMode.sgr,
          motion: true,
          ctrl: true,
          alt: true,
        ),
        equals('\x1B[<59;3;4M'),
      );
    });

    test('report() uses pixel coordinates in sgr-pixels mode', () {
      final output = MouseReporter.report(
        TerminalMouseButton.left,
        TerminalMouseButtonState.down,
        CellOffset(1, 1),
        MouseReportMode.sgrPixels,
        pixelPosition: CellOffset(79, 47),
      );

      expect(output, equals('\x1B[<0;80;48M'));
    });

    test('report() supports urxvt mode', () {
      final output = MouseReporter.report(
        TerminalMouseButton.left,
        TerminalMouseButtonState.down,
        CellOffset(0, 0),
        MouseReportMode.urxvt,
      );

      expect(output, equals('\x1B[32;1;1M'));
    });
  });
}
