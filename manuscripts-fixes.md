# Manuscripts: Bug fixes and QoL improvements to port from Journal

These are bug fixes and quality-of-life changes discovered while building Journal (a fork of Manuscripts). They apply directly to Manuscripts because the underlying prompt_toolkit code is the same.

All line numbers reference the current `manuscripts.py` on `charleskcisco/manuscripts`.

---

## Bug Fixes

### 1. Fix Ctrl+Y redo (critical — currently completely broken)

`buffer.redo()` silently does nothing. Two independent issues:

#### a. `save_before` clears the redo stack before the handler runs

prompt_toolkit's key processor calls `save_to_undo_stack(clear_redo_stack=True)` **before** every key handler. By the time `buffer.redo()` executes, `_redo_stack` is already empty.

**Fix (line ~3091):**
```python
# Before:
@kb.add("c-y", filter=is_editor & no_float)
def _(event):
    editor_area.buffer.redo()

# After:
@kb.add("c-y", filter=is_editor & no_float, save_before=lambda e: False)
def _(event):
    editor_area.buffer.redo()
```

#### b. Terminal `dsusp` intercepts `^Y` before the app sees it

On macOS (and some Linux), `stty` sets `dsusp = ^Y` (delayed suspend). The terminal swallows the keypress before prompt_toolkit enters raw mode.

**Fix — add before `app.run()` in `main()` (around line ~3397):**
```python
# Disable terminal dsusp (^Y) so Ctrl+Y reaches the application
try:
    import termios
    fd = sys.stdin.fileno()
    attrs = termios.tcgetattr(fd)
    VDSUSP = termios.VDSUSP
    attrs[6][VDSUSP] = b'\x00'
    termios.tcsetattr(fd, termios.TCSANOW, attrs)
except (ImportError, AttributeError, termios.error):
    pass
```

---

### 2. Fix left/right arrows not crossing line boundaries

prompt_toolkit's default left/right arrow behavior stops at line boundaries — the cursor won't move from the end of one line to the start of the next. Add custom bindings.

**Add near the other editor key bindings (around line ~3095):**
```python
@kb.add("left", filter=is_editor & no_float)
def _(event):
    buf = editor_area.buffer
    if buf.cursor_position > 0:
        buf.cursor_position -= 1

@kb.add("right", filter=is_editor & no_float)
def _(event):
    buf = editor_area.buffer
    if buf.cursor_position < len(buf.text):
        buf.cursor_position += 1
```

---

### 3. Fix SelectableList not scrolling to follow selection

The `SelectableList` class doesn't emit a `[SetCursorPosition]` marker, so prompt_toolkit's `Window` has no idea where the selected item is. On long lists, the selection scrolls off-screen.

**Fix in `SelectableList.get_formatted_text()` (Manuscripts line ~1010-1017):**
```python
# Before:
for i, (_, label) in enumerate(self.items):
    s = "class:select-list.selected" if i == self.selected_index else ""
    result.append((s, f"  {label}\n"))

# After:
for i, (_, label) in enumerate(self.items):
    if i == self.selected_index:
        result.append(("[SetCursorPosition]", ""))
        result.append(("class:select-list.selected", f"  {label}\n"))
    else:
        result.append(("", f"  {label}\n"))
```

---

## Find/Replace Panel Overhaul

The find/replace workflow needs several coordinated changes. The core logic (`_rebuild_matches`, `_move`, `_replace_one`, `_replace_all`, `_on_changed`, `_scroll_to_cursor`) is identical and doesn't need to change — all changes are in `__init__` and the main keybindings.

### 4. Rework FindReplacePanel.__init__ (line ~2084)

Three changes inside the `__init__` method:

**a. Enter should focus the editor after finding a match (line ~2105-2107):**
```python
# Before:
@search_kb.add("enter")
def _search_enter(event):
    self._move(1)

# After:
@search_kb.add("enter")
def _search_enter(event):
    self._move(1)
    get_app().layout.focus(self.editor_area)
```

**b. Remove the title bar and separator from the HSplit to save vertical space (line ~2167-2171):**

Delete these two lines from the HSplit:
```python
Window(FormattedTextControl(
    [("class:accent bold", " Find/Replace\n")],
), height=1),
Window(height=1, char="─", style="class:hint"),
```

**c. Update the hints and panel dimensions (line ~2159-2180):**

Replace the hints function and adjust the HSplit dimensions:
```python
# Before:
def get_hints():
    return [
        ("class:accent bold", "  Ret"), ("", "  Next / Repl\n"),
        ("class:accent bold", "  Tab"), ("", "  Next field\n"),
        ("class:accent bold", "  ^F "), ("", "  Editor\n"),
        ("class:accent bold", "  Esc"), ("", "  Close\n"),
    ]
# ... height=4), ], width=28 ...

# After:
def get_hints():
    return [
        ("class:accent bold", " ret"), ("", "  Highlight match\n"),
        ("class:accent bold", "  ^k"), ("", "  Next result\n"),
        ("class:accent bold", "  ^j"), ("", "  Previous result\n"),
        ("class:accent bold", "  ^f"), ("", "  Switch panel\n"),
        ("class:accent bold", " esc"), ("", "  Close\n"),
    ]
# ... height=5), ], width=24 ...
```

---

### 5. Add Ctrl+K / Ctrl+J for find-next/prev from the editor

This is the key part — once Enter focuses the editor, the user needs a way to cycle through matches without going back to the panel. These bindings call the find panel's `_rebuild_matches` and `_move` methods from the editor context.

**Add a `find_panel_open` condition (near the other Condition definitions):**
```python
find_panel_open = Condition(
    lambda: state.show_find_panel and state.find_panel is not None)
```

**Add the bindings in the main `kb` (near the other editor keybindings):**
```python
@kb.add("c-k", filter=is_editor & no_float & find_panel_open)
def _(event):
    state.find_panel._rebuild_matches()
    state.find_panel._move(1)

@kb.add("c-j", filter=is_editor & no_float & find_panel_open)
def _(event):
    state.find_panel._rebuild_matches()
    state.find_panel._move(-1)
```

---

## UI Polish

### 7. Remove non-functional dialog button hints

The "(c)", "(y)", "(n)" prefixes on dialog buttons suggest keyboard shortcuts, but they don't work — prompt_toolkit buttons are activated by focus + Enter. Leaving them in is misleading.

**Lines to change:**
- Line ~1378: `"(c) Cancel"` -> `"Cancel"`
- Line ~1429: `"(y) Yes"` -> `"Yes"`
- Line ~1430: `"(n) No"` -> `"No"`
- Line ~1466: `"(c) Cancel"` -> `"Cancel"`
- Line ~1502: `"(c) Cancel"` -> `"Cancel"`
- Line ~1655: `"(c) Cancel"` -> `"Cancel"`
- Line ~1836: `"(c) Close"` -> `"Close"`
- Line ~1894: `"(c) Cancel"` -> `"Cancel"`

---

### 8. Lowercase key names in notifications and hints

Notification messages use inconsistent capitalization ("Press Ctrl+Q again" vs. keybinding labels). Standardize to lowercase shorthand.

**Notification messages to change:**
- Line ~2937: `"Press Esc again to return to manuscripts."` -> `"Press esc again to return to manuscripts."`
- Line ~2954: `"Press Ctrl+Q again to quit."` -> `"Press ^q again to quit."`
- Line ~3080: `"Press Ctrl+S again to shut down."` -> `"Press ^s again to shut down."`

**Keybindings panel labels (line ~2522-2540) — lowercase the keys:**
```python
# Before:
("Esc", "Manuscripts"), ("^O", "Sources"), ("^P", "Commands"), ...
# After:
("esc", "Manuscripts"), ("^o", "Sources"), ("^p", "Commands"), ...
```

---

### 9. Add dynamic "press again" confirmation to shutdown hint on projects screen

Currently the shutdown hint on the projects screen is static text. It should reflect the "press again" state like the notification does, giving visual feedback.

**Fix (line ~2318-2319):**
```python
# Before:
shutdown_hint_control = FormattedTextControl(
    lambda: [("class:hint", "⌃S Shut down ")])

# After:
def _get_shutdown_hint():
    now = time.monotonic()
    if state.shutdown_pending and now - state.shutdown_pending < 2.0:
        return [("class:accent bold", " (^s) press again to shut down ")]
    return [("class:hint", " (^s) shut down ")]

shutdown_hint_control = FormattedTextControl(_get_shutdown_hint)
```

---

### 10. Add ^q quit hint to projects screen

The ^q quit binding works on the projects screen but there's no visible hint for it. Add it alongside the shutdown hint.

**Fix (line ~2318) — also show a "press again" state for quit:**
```python
def _get_shutdown_hint():
    now = time.monotonic()
    if now - state.quit_pending < 2.0:
        return [("class:accent bold", " (^q) press again to quit ")]
    if state.shutdown_pending and now - state.shutdown_pending < 2.0:
        return [("class:accent bold", " (^s) press again to shut down ")]
    return [("class:hint", " (^s) shut down ")]
```

---

### 11. Make keybindings panel responsive

On wider terminals, display the keybindings in two columns. On narrow terminals (writerdeck), keep the single-column layout.

**Fix (line ~2522-2545):**
```python
def _keybindings_panel_width():
    return 40 if shutil.get_terminal_size().columns >= 100 else 22

# Replace the fixed `keybindings_panel = Window(..., width=22)` with a
# dynamically-created Window using width=_keybindings_panel_width()
# inside get_editor_body(), so it recalculates on each render.

# In get_keybindings_text(), add a wide-terminal branch that renders
# _KB_ALL in two columns when cols >= 100.
```

---

## Performance

### 12. Cache clipboard tool detection at startup

Currently, `_clipboard_copy` and `_clipboard_paste` (lines ~1322-1342) iterate through tool candidates on every call, spawning subprocesses. Cache the working tool once at startup.

**Fix — replace the clipboard functions with a cached approach:**
```python
_clip_copy_cmd = None
_clip_paste_cmd = None

for cmd in [["wl-copy"], ["xclip", "-selection", "clipboard"]]:
    if shutil.which(cmd[0]):
        _clip_copy_cmd = cmd
        break

for cmd in [["wl-paste", "--no-newline"], ["xclip", "-selection", "clipboard", "-o"]]:
    if shutil.which(cmd[0]):
        _clip_paste_cmd = cmd
        break

def _clipboard_copy(text):
    if _clip_copy_cmd:
        try:
            subprocess.run(_clip_copy_cmd, input=text, text=True, timeout=2)
            return True
        except subprocess.TimeoutExpired:
            return False
    return False

def _clipboard_paste():
    if _clip_paste_cmd:
        try:
            result = subprocess.run(_clip_paste_cmd, capture_output=True, text=True, timeout=2)
            if result.returncode == 0:
                return result.stdout
        except subprocess.TimeoutExpired:
            pass
    return None
```

---

### 13. Hide dotfiles from project list

Prevent `.DS_Store` and other dotfiles from appearing in the project listing.

**Fix in the project listing method (where `*.json` files are globbed, line ~241):**
```python
for p in self.projects_dir.glob("*.json"):
    if p.name.startswith("."):
        continue
    # ... rest of listing
```

---

## Optional: Word count default

### 14. Default word count to "off"

Add a third "off" state to the word/paragraph count cycle and default to it.

**Fix (line ~1259):**
```python
self.show_word_count = 2  # 0=words, 1=paragraphs, 2=off
```

**Fix (line ~3107-3110):**
```python
@kb.add("c-w", filter=is_editor & no_float)
def _(event):
    state.show_word_count = (state.show_word_count + 1) % 3
    get_app().invalidate()
```

**Update the status bar display to handle three states (0=words, 1=paragraphs, 2=off).**

---

## New Features

### 15. Pin projects to top of project list

Add a `p` keybinding on the projects screen to pin/unpin projects. Pinned projects sort to the top of the list with a `*` prefix, preserving relative order among themselves.

**State**: Add `self.pinned_paths: set[str] = set()` to `AppState.__init__`. Load from `~/.config/manuscripts/config.json` under a `"pinned"` key (list of project names).

**Sort**: In the project listing method, partition into pinned and unpinned, then concatenate `pinned + unpinned`.

**Display**: Prefix pinned projects with `* `, unpinned with `  `.

**Keybinding**: Add `@kb.add("p", filter=project_list_focused)` that toggles the selected project's name in `state.pinned_paths`, persists to config, and refreshes the list.

**Hints**: Add `(p) pin` to the project screen title hints.

**Config format** (`~/.config/manuscripts/config.json`):
```json
{
  "pinned": ["my-novel", "short-story"]
}
```

---

### 16. Set cursor below YAML frontmatter when opening an entry

When opening an entry whose text starts with YAML frontmatter (`---\n...\n---\n`), place the cursor after the closing fence instead of at position 0. This keeps the user from accidentally editing metadata.

**Fix — in `open_entry` (or equivalent), after setting `editor_area.text`:**
```python
# Place cursor below YAML front matter
cursor_pos = 0
if content.startswith("---\n"):
    end = content.find("\n---\n", 4)
    if end != -1:
        cursor_pos = end + 5
        # Skip trailing blank lines after front matter
        while cursor_pos < len(content) and content[cursor_pos] == "\n":
            cursor_pos += 1
editor_area.buffer.cursor_position = cursor_pos
```

---

## Not ported (Journal-specific)

These changes were made in Journal but don't apply to Manuscripts:
- Recursive `.md` file listing (Manuscripts uses flat JSON storage)
- Vault path config with `config.json` (Manuscripts has its own `MANUSCRIPTS_DATA` env var)
- Preview pane with word wrapping (Journal shows `.md` previews; not relevant to JSON projects)
- .bib file discovery and error reporting improvements (Manuscripts doesn't use .bib)
- Citation picker simplified to citekeys only (Journal-specific)

---

## Verification

- Open a project, type text, Ctrl+Z to undo, then Ctrl+Y — text should reappear
- Left/right arrows should cross line boundaries smoothly
- In find panel, Enter should jump to match and focus editor; Ctrl+K/J should cycle matches from editor
- Find panel should fit comfortably on a 1280x400 display
- Dialogs should show clean button labels without letter prefixes
- Notifications should use lowercase key names (^q, ^s, esc)
- Shutdown and quit hints should show "press again" confirmation
- Keybindings panel should use two columns on wide terminals
- Copy/paste should still work after clipboard caching
- Ctrl+W should cycle: words -> paragraphs -> off -> words
- Dotfiles should not appear in the project list
- Pin a project with `p` — it moves to the top with a `*` prefix
- Unpin with `p` — it returns to its chronological position
- Pinned projects persist across restarts (stored in config.json)
- Open an entry with YAML frontmatter — cursor should be on the first line of body text, not in the metadata
