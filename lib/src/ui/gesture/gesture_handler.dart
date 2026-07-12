import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:xterm/src/core/mouse/button.dart';
import 'package:xterm/src/core/mouse/button_state.dart';
import 'package:xterm/src/terminal_view.dart';
import 'package:xterm/src/ui/controller.dart';
import 'package:xterm/src/ui/gesture/gesture_detector.dart';
import 'package:xterm/src/ui/pointer_input.dart';
import 'package:xterm/src/ui/render.dart';

class TerminalGestureHandler extends StatefulWidget {
  const TerminalGestureHandler({
    super.key,
    required this.terminalView,
    required this.terminalController,
    this.child,
    this.onTapUp,
    this.onSingleTapUp,
    this.onTapDown,
    this.onSecondaryTapDown,
    this.onSecondaryTapUp,
    this.onTertiaryTapDown,
    this.onTertiaryTapUp,
    this.readOnly = false,
  });

  final TerminalViewState terminalView;

  final TerminalController terminalController;

  final Widget? child;

  final GestureTapUpCallback? onTapUp;

  final GestureTapUpCallback? onSingleTapUp;

  final GestureTapDownCallback? onTapDown;

  final GestureTapDownCallback? onSecondaryTapDown;

  final GestureTapUpCallback? onSecondaryTapUp;

  final GestureTapDownCallback? onTertiaryTapDown;

  final GestureTapUpCallback? onTertiaryTapUp;

  final bool readOnly;

  @override
  State<TerminalGestureHandler> createState() => _TerminalGestureHandlerState();
}

class _TerminalGestureHandlerState extends State<TerminalGestureHandler> {
  TerminalViewState get terminalView => widget.terminalView;

  RenderTerminal get renderTerminal => terminalView.renderTerminal;

  DragStartDetails? _lastDragStartDetails;

  Offset? _lastDragPosition;

  bool _primaryDownReported = false;

  bool _trackedTapUpHandled = false;

  bool _forwardingDrag = false;

  LongPressStartDetails? _lastLongPressStartDetails;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: onHover,
      child: TerminalGestureDetector(
        child: widget.child,
        onTapUp: onTapUp,
        onSingleTapUp: onSingleTapUp,
        onTapDown: onTapDown,
        onSecondaryTapDown: onSecondaryTapDown,
        onSecondaryTapUp: onSecondaryTapUp,
        onTertiaryTapDown: onTertiaryTapDown,
        onTertiaryTapUp: onTertiaryTapUp,
        onLongPressStart: onLongPressStart,
        onLongPressMoveUpdate: onLongPressMoveUpdate,
        onDragStart: onDragStart,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
        onDragCancel: onDragCancel,
        onDoubleTapDown: onDoubleTapDown,
      ),
    );
  }

  bool _shouldSendPointerInput(PointerInput input) =>
      !widget.readOnly &&
      !HardwareKeyboard.instance.isShiftPressed &&
      widget.terminalController.shouldSendPointerInput(input);

  bool get _ctrlPressed => HardwareKeyboard.instance.isControlPressed;

  bool get _altPressed => HardwareKeyboard.instance.isAltPressed;

  bool _tapDown(
    GestureTapDownCallback? callback,
    TapDownDetails details,
    TerminalMouseButton button, {
    bool forceCallback = false,
  }) {
    // Check if the terminal should and can handle the tap down event.
    var handled = false;
    if (_shouldSendPointerInput(PointerInput.tap)) {
      handled = renderTerminal.mouseEvent(
        button,
        TerminalMouseButtonState.down,
        details.localPosition,
        ctrl: _ctrlPressed,
        alt: _altPressed,
      );
    }
    // If the event was not handled by the terminal, use the supplied callback.
    if (!handled || forceCallback) {
      callback?.call(details);
    }
    return handled;
  }

  void _tapUp(
    GestureTapUpCallback? callback,
    TapUpDetails details,
    TerminalMouseButton button, {
    bool forceCallback = false,
  }) {
    // Check if the terminal should and can handle the tap up event.
    var handled = false;
    if (_shouldSendPointerInput(PointerInput.tap)) {
      handled = renderTerminal.mouseEvent(
        button,
        TerminalMouseButtonState.up,
        details.localPosition,
        ctrl: _ctrlPressed,
        alt: _altPressed,
      );
    }
    // If the event was not handled by the terminal, use the supplied callback.
    if (!handled || forceCallback) {
      callback?.call(details);
    }
  }

  void onTapDown(TapDownDetails details) {
    // onTapDown is special, as it will always call the supplied callback.
    // The TerminalView depends on it to bring the terminal into focus.
    _trackedTapUpHandled = false;
    _primaryDownReported = _tapDown(
      widget.onTapDown,
      details,
      TerminalMouseButton.left,
      forceCallback: true,
    );
  }

  void onTapUp(TapUpDetails details) {
    if (_primaryDownReported) {
      renderTerminal.mouseEvent(
        TerminalMouseButton.left,
        TerminalMouseButtonState.up,
        details.localPosition,
        ctrl: _ctrlPressed,
        alt: _altPressed,
      );
      _primaryDownReported = false;
      _trackedTapUpHandled = true;
      return;
    }
    widget.onTapUp?.call(details);
  }

  void onSingleTapUp(TapUpDetails details) {
    if (_trackedTapUpHandled) {
      _trackedTapUpHandled = false;
      return;
    }
    widget.onSingleTapUp?.call(details);
  }

  void onSecondaryTapDown(TapDownDetails details) {
    _tapDown(widget.onSecondaryTapDown, details, TerminalMouseButton.right);
  }

  void onSecondaryTapUp(TapUpDetails details) {
    _tapUp(widget.onSecondaryTapUp, details, TerminalMouseButton.right);
  }

  void onTertiaryTapDown(TapDownDetails details) {
    _tapDown(widget.onTertiaryTapDown, details, TerminalMouseButton.middle);
  }

  void onTertiaryTapUp(TapUpDetails details) {
    _tapUp(widget.onTertiaryTapUp, details, TerminalMouseButton.middle);
  }

  void onDoubleTapDown(TapDownDetails details) {
    if (!_primaryDownReported) {
      renderTerminal.selectWord(details.localPosition);
    }
  }

  void onLongPressStart(LongPressStartDetails details) {
    _lastLongPressStartDetails = details;
    renderTerminal.selectWord(details.localPosition);
  }

  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    renderTerminal.selectWord(
      _lastLongPressStartDetails!.localPosition,
      details.localPosition,
    );
  }

  // void onLongPressUp() {}

  void onDragStart(DragStartDetails details) {
    _lastDragStartDetails = details;
    _lastDragPosition = details.localPosition;
    _forwardingDrag =
        _primaryDownReported && _shouldSendPointerInput(PointerInput.drag);
    if (_forwardingDrag) {
      return;
    }
    if (_primaryDownReported) {
      renderTerminal.mouseEvent(
        TerminalMouseButton.left,
        TerminalMouseButtonState.up,
        details.localPosition,
      );
      _primaryDownReported = false;
    }

    details.kind == PointerDeviceKind.mouse
        ? renderTerminal.selectCharacters(details.localPosition)
        : renderTerminal.selectWord(details.localPosition);
  }

  void onDragUpdate(DragUpdateDetails details) {
    _lastDragPosition = details.localPosition;
    if (_forwardingDrag) {
      renderTerminal.mouseEvent(
        TerminalMouseButton.left,
        TerminalMouseButtonState.down,
        details.localPosition,
        motion: true,
        ctrl: _ctrlPressed,
        alt: _altPressed,
      );
      return;
    }
    renderTerminal.selectCharacters(
      _lastDragStartDetails!.localPosition,
      details.localPosition,
    );
  }

  void onDragEnd(DragEndDetails details) => _finishDrag();

  void onDragCancel() => _finishDrag();

  void _finishDrag() {
    final position = _lastDragPosition;
    if (_forwardingDrag && _primaryDownReported && position != null) {
      renderTerminal.mouseEvent(
        TerminalMouseButton.left,
        TerminalMouseButtonState.up,
        position,
        ctrl: _ctrlPressed,
        alt: _altPressed,
      );
    }
    _primaryDownReported = false;
    _forwardingDrag = false;
    _lastDragPosition = null;
  }

  void onHover(PointerHoverEvent event) {
    if (!_shouldSendPointerInput(PointerInput.move)) {
      return;
    }
    renderTerminal.mouseEvent(
      TerminalMouseButton.none,
      TerminalMouseButtonState.down,
      event.localPosition,
      motion: true,
      ctrl: _ctrlPressed,
      alt: _altPressed,
    );
  }
}
