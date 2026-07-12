# Alera patches

This fork is consumed by Alera as a Git submodule while the terminal fixes are reviewed upstream.

## Fork metadata

- Fork: <https://github.com/leynier/xterm.dart.git>
- Integration branch: `next`
- Upstream: <https://github.com/TerminalStudio/xterm.dart>
- Scroll-region upstream pull request: <https://github.com/TerminalStudio/xterm.dart/pull/227>

## Changes

- Move scroll-region buffer lines safely so scroll-region updates do not detach indexed buffer rows.
- Clear stale alternate-buffer and main-buffer cells after resize so full-screen terminal apps do not show old rows after the viewport changes.
- Skip app reflow while cursor-hidden apps redraw their own frame, preventing stale TUI content from being reintroduced during resize.
- Preserve empty cells between copied text columns when serializing selected buffer text. TUI apps can draw columns by moving the cursor instead of writing literal space characters; those visual gaps should copy as spaces.
- Encode wheel reports with canonical button IDs and route wheel events in either buffer while an application has enabled mouse tracking.
- Report button motion, hover motion, modifier keys, and SGR pixel coordinates for DEC mouse modes 1002, 1003, and 1016.
- Let tracked TUIs own pointer gestures while preserving Shift-drag as an explicit local-selection override.
- Make Ctrl+C copy a local selection on non-Apple platforms and preserve the interrupt byte when no selection exists.
- Expose clipboard callbacks and configurable TUI wheel sensitivity to the embedding application.

## Why Alera carries this fork

Alera embeds terminal sessions that run interactive TUIs such as Claude Code, Codex, OpenCode, Amp, Gemini, and similar agents. Those apps rely heavily on resize handling, scroll regions, alternate buffers, mouse reporting, cursor positioning, and visual columns. The fork keeps the minimal fixes available to Alera until upstream can merge and release them.
