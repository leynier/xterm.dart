import 'package:xterm/src/core/buffer/cell_offset.dart';
import 'package:xterm/src/core/mouse/mode.dart';
import 'package:xterm/src/core/mouse/button.dart';
import 'package:xterm/src/core/mouse/button_state.dart';

abstract class MouseReporter {
  static String report(
    TerminalMouseButton button,
    TerminalMouseButtonState state,
    CellOffset position,
    MouseReportMode reportMode, {
    CellOffset? pixelPosition,
    bool motion = false,
    bool ctrl = false,
    bool alt = false,
    bool shift = false,
  }) {
    final resolvedPosition = reportMode == MouseReportMode.sgrPixels
        ? pixelPosition ?? position
        : position;
    // x and y offsets have to be incremented by 1 as the offset if 0-based,
    // The position has to be reported using 1-based coordinates.
    final x = resolvedPosition.x + 1;
    final y = resolvedPosition.y + 1;
    var buttonID = state == TerminalMouseButtonState.up ? 3 : button.id;
    if (motion) buttonID = button.id + 32;
    if (shift) buttonID += 4;
    if (alt) buttonID += 8;
    if (ctrl) buttonID += 16;
    switch (reportMode) {
      case MouseReportMode.normal:
      case MouseReportMode.utf:
        // The button ID is reported as shifted by 32 to produce a printable
        // character.
        final btn = String.fromCharCode(32 + buttonID);
        // Normal mode only supports a maximum position of 223, while utf
        // supports positions up to 2015. Both modes send a null byte if the
        // position exceeds that limit.
        final col = (reportMode == MouseReportMode.normal && x > 223) ||
                (reportMode == MouseReportMode.utf && x > 2015)
            ? '\x00'
            : String.fromCharCode(32 + x);
        final row = (reportMode == MouseReportMode.normal && y > 223) ||
                (reportMode == MouseReportMode.utf && y > 2015)
            ? '\x00'
            : String.fromCharCode(32 + y);
        return "\x1b[M$btn$col$row";
      case MouseReportMode.sgr:
      case MouseReportMode.sgrPixels:
        buttonID = motion ? button.id + 32 : button.id;
        if (shift) buttonID += 4;
        if (alt) buttonID += 8;
        if (ctrl) buttonID += 16;
        final upDown = state == TerminalMouseButtonState.down ? 'M' : 'm';
        return "\x1b[<$buttonID;$x;$y$upDown";
      case MouseReportMode.urxvt:
        return "\x1b[${32 + buttonID};$x;${y}M";
    }
  }
}
