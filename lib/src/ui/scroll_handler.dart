import 'package:flutter/widgets.dart';
import 'package:xterm/core.dart';
import 'package:xterm/src/ui/controller.dart';
import 'package:xterm/src/ui/infinite_scroll_view.dart';
import 'package:xterm/src/ui/pointer_input.dart';

/// Handles scrolling gestures in the alternate screen buffer. In alternate
/// screen buffer, the terminal don't have a scrollback buffer, instead, the
/// scroll gestures are converted to escape sequences based on the current
/// report mode declared by the application.
class TerminalScrollGestureHandler extends StatefulWidget {
  const TerminalScrollGestureHandler({
    super.key,
    required this.terminal,
    required this.controller,
    required this.getCellOffset,
    required this.getPixelOffset,
    required this.getLineHeight,
    this.simulateScroll = true,
    this.mouseWheelSensitivity = 1,
    required this.child,
  });

  final Terminal terminal;

  final TerminalController controller;

  /// Returns the cell offset for the pixel offset.
  final CellOffset Function(Offset) getCellOffset;

  /// Returns the zero-based terminal pixel offset for a local widget offset.
  final CellOffset Function(Offset) getPixelOffset;

  /// Returns the pixel height of lines in the terminal.
  final double Function() getLineHeight;

  /// Whether to simulate scroll events in the terminal when the application
  /// doesn't declare it supports mouse wheel events. true by default as it
  /// is the default behavior of most terminals.
  final bool simulateScroll;

  final int mouseWheelSensitivity;

  final Widget child;

  @override
  State<TerminalScrollGestureHandler> createState() =>
      _TerminalScrollGestureHandlerState();
}

class _TerminalScrollGestureHandlerState
    extends State<TerminalScrollGestureHandler> {
  /// Whether the application is in alternate screen buffer. If false, then this
  /// widget does nothing.
  var interceptsScroll = false;

  /// The variable that tracks the line offset in last scroll event. Used to
  /// determine how many the scroll events should be sent to the terminal.
  var lastLineOffset = 0;

  /// This variable tracks the last offset where the scroll gesture started.
  /// Used to calculate the cell offset of the terminal mouse event.
  var lastPointerPosition = Offset.zero;

  @override
  void initState() {
    widget.terminal.addListener(_onTerminalUpdated);
    interceptsScroll = _shouldInterceptScroll();
    super.initState();
  }

  @override
  void dispose() {
    widget.terminal.removeListener(_onTerminalUpdated);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TerminalScrollGestureHandler oldWidget) {
    if (oldWidget.terminal != widget.terminal) {
      oldWidget.terminal.removeListener(_onTerminalUpdated);
      widget.terminal.addListener(_onTerminalUpdated);
      interceptsScroll = _shouldInterceptScroll();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _onTerminalUpdated() {
    final next = _shouldInterceptScroll();
    if (interceptsScroll != next) {
      interceptsScroll = next;
      lastLineOffset = 0;
      setState(() {});
    }
  }

  bool _shouldInterceptScroll() {
    if (widget.terminal.isUsingAltBuffer) {
      return true;
    }
    return widget.terminal.mouseMode.reportScroll &&
        widget.controller.shouldSendPointerInput(PointerInput.scroll);
  }

  /// Send a single scroll event to the terminal. If [simulateScroll] is true,
  /// then if the application doesn't recognize mouse wheel events, this method
  /// will simulate scroll events by sending up/down arrow keys.
  void _sendScrollEvent(bool up) {
    final position = widget.getCellOffset(lastPointerPosition);
    final pixelPosition = widget.getPixelOffset(lastPointerPosition);

    final handled = widget.terminal.mouseInput(
      up ? TerminalMouseButton.wheelUp : TerminalMouseButton.wheelDown,
      TerminalMouseButtonState.down,
      position,
      pixelPosition: pixelPosition,
    );

    if (handled) {
      final repeatCount = widget.mouseWheelSensitivity.clamp(1, 10);
      for (var i = 1; i < repeatCount; i += 1) {
        widget.terminal.mouseInput(
          up ? TerminalMouseButton.wheelUp : TerminalMouseButton.wheelDown,
          TerminalMouseButtonState.down,
          position,
          pixelPosition: pixelPosition,
        );
      }
      return;
    }

    if (widget.simulateScroll) {
      widget.terminal.keyInput(
        up ? TerminalKey.arrowUp : TerminalKey.arrowDown,
      );
    }
  }

  void _onScroll(double offset) {
    final currentLineOffset = offset ~/ widget.getLineHeight();

    final delta = currentLineOffset - lastLineOffset;

    for (var i = 0; i < delta.abs(); i++) {
      _sendScrollEvent(delta < 0);
    }

    lastLineOffset = currentLineOffset;
  }

  @override
  Widget build(BuildContext context) {
    if (!interceptsScroll) {
      return widget.child;
    }

    return Listener(
      onPointerSignal: (event) {
        lastPointerPosition = event.localPosition;
      },
      onPointerDown: (event) {
        lastPointerPosition = event.localPosition;
      },
      child: InfiniteScrollView(
        onScroll: _onScroll,
        child: widget.child,
      ),
    );
  }
}
