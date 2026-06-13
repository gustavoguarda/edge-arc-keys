# edge-arc-keys

Arc/Zen-style keyboard shortcuts for **Microsoft Edge** — toggle the vertical
tabs sidebar and copy the active tab's URL with a single keystroke. macOS
(Hammerspoon) and Windows (AutoHotkey).

Edge has great vertical tabs, but the keyboard ergonomics aren't quite Arc/Zen.
This bridges that gap with global, Edge-only shortcuts.

## Features

| Feature | macOS (Spoon) | Windows (AHK) |
| --- | :---: | :---: |
| Toggle Vertical Tabs sidebar | ✅ | ✅ |
| Copy active tab URL | ✅ | ✅ |

Default shortcuts:

| Action | macOS | Windows |
| --- | --- | --- |
| Toggle sidebar | `Cmd+S` | `Ctrl+S` |
| Copy URL | `Cmd+Shift+C` | `Ctrl+Shift+C` |

Shortcuts are only active while Edge is focused, so they don't shadow Save
(`Cmd/Ctrl+S`) or other apps' bindings.

The sidebar toggle is the interesting bit: when the pane is collapsed, Edge only
shows the "Pin pane" control on a real mouse hover over the left edge — so the
shortcut briefly simulates that hover, pins the pane open, and restores the
cursor.

## Install — macOS (Hammerspoon)

1. Install [Hammerspoon](https://www.hammerspoon.org/): `brew install --cask hammerspoon`.
2. Download this repo and place `EdgeArcKeys.spoon` in `~/.hammerspoon/Spoons/`
   (double-clicking the `.spoon` bundle also installs it).
3. Add to your `~/.hammerspoon/init.lua`:

   ```lua
   hs.loadSpoon("EdgeArcKeys")

   -- Use the defaults, or pass your own { {mods}, key } pairs
   spoon.EdgeArcKeys:bindHotkeys(spoon.EdgeArcKeys.defaultHotkeys)
   spoon.EdgeArcKeys:start()
   ```

4. Reload Hammerspoon (menu bar → Reload Config).

### Permissions (macOS)

Grant Hammerspoon **Accessibility** in System Settings → Privacy & Security
(needed to read Edge's UI tree and simulate the edge hover). The first time you
use copy-URL, macOS may also prompt for **Automation** (Hammerspoon →
Microsoft Edge).

### Custom shortcuts (macOS)

```lua
spoon.EdgeArcKeys:bindHotkeys({
  toggleSidebar = { {"cmd"},          "s" },
  copyUrl       = { {"cmd", "shift"}, "c" },
})
```

Omit a key to leave that action unbound.

## Install — Windows (AutoHotkey)

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. For the sidebar toggle, download `UIA.ahk` from
   [Descolada/UIA-v2](https://github.com/Descolada/UIA-v2) and put it next to
   `edge.ahk` in `windows/`. (Copy-URL works without it.)
3. Run `windows/edge.ahk` (double-click). To start with Windows, place a
   shortcut to it in `shell:startup`.

## License

[MIT](LICENSE)
