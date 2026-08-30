# Alera patches

This repository preserves the original Alera xterm.dart fork. New Alera integrations use https://github.com/leynier/xterm2. The original fixes remain in this repository and it is not archived.

## Fork metadata

- Fork: <https://github.com/leynier/xterm.dart.git>
- Integration and default branch: `next`
- Branch policy: `next` is the only permanent remote branch; merged feature branches are deleted automatically.
- Upstream: <https://github.com/TerminalStudio/xterm.dart>
- Scroll-region upstream pull request: <https://github.com/TerminalStudio/xterm.dart/pull/227>

## Changes

- Move scroll-region buffer lines safely so scroll-region updates do not detach indexed buffer rows.
- Clear stale alternate-buffer and main-buffer cells after resize so full-screen terminal apps do not show old rows after the viewport changes.
- Skip app reflow while cursor-hidden apps redraw their own frame, preventing stale TUI content from being reintroduced during resize.
- Reset the circular buffer origin before adopting reflow results so trimmed scrollback cannot expose stale rows with the old width.
- Release circular-buffer rows when trimming scrollback so dropped terminal cells do not remain strongly referenced, and keep survivor indexes aligned.
- Compact buffer rows once they scroll into history, releasing the trailing all-zero capacity every row keeps for in-place edits. History rows regrow with zero cells if they re-enter the viewport, styled erases keep their colored cells, and word-boundary plus combining-mark reads clamp to the compacted row length.
- Decode parser input into preallocated code-point blocks instead of `String.runes.toList()`, move buffer-line block copies through `setRange`, and reuse one `Paint` for solid rectangles so sustained output allocates less on the UI isolate.
- Preserve empty cells between copied text columns when serializing selected buffer text. TUI apps can draw columns by moving the cursor instead of writing literal space characters; those visual gaps should copy as spaces.
- Encode wheel reports with canonical button IDs and route wheel events in either buffer while an application has enabled mouse tracking.
- Report button motion, hover motion, modifier keys, and SGR pixel coordinates for DEC mouse modes 1002, 1003, and 1016.
- Let tracked TUIs own pointer gestures while preserving Shift-drag as an explicit local-selection override.
- Make Ctrl+C copy a local selection on non-Apple platforms and preserve the interrupt byte when no selection exists.
- Expose clipboard callbacks and configurable TUI wheel sensitivity to the embedding application.

## Why Alera carries this fork

Alera embeds terminal sessions that run interactive TUIs such as Claude Code, Codex, OpenCode, Amp, Gemini, and similar agents. Those apps rely heavily on resize handling, scroll regions, alternate buffers, mouse reporting, cursor positioning, and visual columns. The fork keeps the minimal fixes available to Alera for older consumers. The upstream pull request above was closed without merging.

## Consolidation

The consolidated history contains `14ebe14844b5f35cff20c582f09fd97dd6bedc28` and all ten pre-consolidation branch tips. Tags and releases remain intact. Automatic tagging is disabled; a normal push to `next` does not publish a release.
