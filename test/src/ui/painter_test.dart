import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/src/ui/painter.dart';
import 'package:xterm/xterm.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TerminalPainter.paintCursor', () {
    test('paints vertical bar cursor at the provided cell offset', () async {
      final painter = _createPainter();
      const offset = ui.Offset(18, 28);
      final pixels = await _paintCursor(
        painter,
        offset,
        TerminalCursorType.verticalBar,
      );

      expect(
        _paintedPixels(
          pixels,
          _cursorBand(
            x: offset.dx - 2,
            y: offset.dy - 1,
            width: 5,
            height: painter.cellSize.height + 2,
          ),
        ),
        greaterThan(0),
      );
      expect(
        _paintedPixels(
          pixels,
          _cursorBand(
            x: offset.dx - 2,
            y: 0,
            width: 5,
            height: offset.dy - 3,
          ),
        ),
        isZero,
      );
    });

    test('keeps vertical bar shape when cursor is inactive', () async {
      final painter = _createPainter();
      const offset = ui.Offset(18, 28);
      final pixels = await _paintCursor(
        painter,
        offset,
        TerminalCursorType.verticalBar,
        hasFocus: false,
      );

      expect(
        _paintedPixels(
          pixels,
          _cursorBand(
            x: offset.dx - 2,
            y: offset.dy - 1,
            width: 5,
            height: painter.cellSize.height + 2,
          ),
        ),
        greaterThan(0),
      );
      expect(
        _paintedPixels(
          pixels,
          _cursorBand(
            x: offset.dx + 3,
            y: offset.dy + 1,
            width: painter.cellSize.width - 4,
            height: painter.cellSize.height - 2,
          ),
        ),
        isZero,
      );
    });

    test('paints underline cursor at the provided cell offset', () async {
      final painter = _createPainter();
      const offset = ui.Offset(18, 28);
      final underlineY = offset.dy + painter.cellSize.height - 1;
      final pixels = await _paintCursor(
        painter,
        offset,
        TerminalCursorType.underline,
      );

      expect(
        _paintedPixels(
          pixels,
          _cursorBand(
            x: offset.dx - 1,
            y: underlineY - 2,
            width: painter.cellSize.width + 3,
            height: 5,
          ),
        ),
        greaterThan(0),
      );
      expect(
        _paintedPixels(
          pixels,
          _cursorBand(
            x: offset.dx - 1,
            y: painter.cellSize.height - 3,
            width: painter.cellSize.width + 3,
            height: 5,
          ),
        ),
        isZero,
      );
    });

    test('keeps underline shape when cursor is inactive', () async {
      final painter = _createPainter();
      const offset = ui.Offset(18, 28);
      final underlineY = offset.dy + painter.cellSize.height - 1;
      final pixels = await _paintCursor(
        painter,
        offset,
        TerminalCursorType.underline,
        hasFocus: false,
      );

      expect(
        _paintedPixels(
          pixels,
          _cursorBand(
            x: offset.dx - 1,
            y: underlineY - 2,
            width: painter.cellSize.width + 3,
            height: 5,
          ),
        ),
        greaterThan(0),
      );
      expect(
        _paintedPixels(
          pixels,
          _cursorBand(
            x: offset.dx + 1,
            y: offset.dy,
            width: painter.cellSize.width - 2,
            height: painter.cellSize.height - 5,
          ),
        ),
        isZero,
      );
    });

    test('keeps block cursor outlined when cursor is inactive', () async {
      final painter = _createPainter();
      const offset = ui.Offset(18, 28);
      final pixels = await _paintCursor(
        painter,
        offset,
        TerminalCursorType.block,
        hasFocus: false,
      );

      expect(
        _paintedPixels(
          pixels,
          _cursorBand(
            x: offset.dx - 1,
            y: offset.dy - 1,
            width: painter.cellSize.width + 2,
            height: painter.cellSize.height + 2,
          ),
        ),
        greaterThan(0),
      );
      expect(
        _paintedPixels(
          pixels,
          _cursorBand(
            x: offset.dx + 3,
            y: offset.dy + 3,
            width: painter.cellSize.width - 6,
            height: painter.cellSize.height - 6,
          ),
        ),
        isZero,
      );
    });
  });
}

const _imageSize = 96;

TerminalPainter _createPainter() {
  return TerminalPainter(
    theme: TerminalThemes.whiteOnBlack,
    textStyle: const TerminalStyle(),
    textScaler: TextScaler.noScaling,
  );
}

Future<Uint8List> _paintCursor(
  TerminalPainter painter,
  ui.Offset offset,
  TerminalCursorType cursorType, {
  bool hasFocus = true,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  painter.paintCursor(
    canvas,
    offset,
    cursorType: cursorType,
    hasFocus: hasFocus,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(_imageSize, _imageSize);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final pixels = Uint8List.fromList(byteData!.buffer.asUint8List());

  image.dispose();
  picture.dispose();

  return pixels;
}

ui.Rect _cursorBand({
  required double x,
  required double y,
  required double width,
  required double height,
}) {
  return ui.Rect.fromLTWH(x, y, width, height);
}

int _paintedPixels(Uint8List pixels, ui.Rect rect) {
  final left = rect.left.floor().clamp(0, _imageSize).toInt();
  final top = rect.top.floor().clamp(0, _imageSize).toInt();
  final right = rect.right.ceil().clamp(0, _imageSize).toInt();
  final bottom = rect.bottom.ceil().clamp(0, _imageSize).toInt();

  var count = 0;
  for (var y = top; y < bottom; y++) {
    for (var x = left; x < right; x++) {
      final alphaIndex = ((y * _imageSize + x) * 4) + 3;
      if (pixels[alphaIndex] > 0) {
        count++;
      }
    }
  }

  return count;
}
