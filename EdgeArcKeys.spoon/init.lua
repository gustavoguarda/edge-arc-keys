--- === EdgeArcKeys ===
---
--- Arc/Zen-style keyboard shortcuts for Microsoft Edge on macOS.
---
---   toggleSidebar  toggle the Vertical Tabs sidebar
---   copyUrl        copy the active tab's URL
---
--- Shortcuts are only active while Edge is focused (via an app watcher), so they
--- don't swallow Cmd+S ("Save") or Cmd+Shift+C in other apps.
---
--- Usage:
---   hs.loadSpoon("EdgeArcKeys")
---   spoon.EdgeArcKeys:bindHotkeys(spoon.EdgeArcKeys.defaultHotkeys)
---   spoon.EdgeArcKeys:start()

local axuielement = require("hs.axuielement")

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "EdgeArcKeys"
obj.version = "1.0.0"
obj.author = "Gustavo Guarda"
obj.homepage = "https://github.com/gustavoguarda/edge-arc-keys"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- EdgeArcKeys.defaultHotkeys
--- Variable
--- Default hotkey mapping. Pass to `:bindHotkeys()` or provide your own.
obj.defaultHotkeys = {
    toggleSidebar = { { "cmd" }, "s" },
    copyUrl       = { { "cmd", "shift" }, "c" },
}

-- Internal state
obj._hotkeys = {}
obj._watcher = nil

-- Find an AXButton in the Edge window with the given AXDescription and AXPress
-- it. Skips AXWebArea: the tab-pane buttons live in the chrome only, so pruning
-- the page tree keeps the search fast even on heavy pages.
local function pressPaneButton(targetDesc)
    local app = hs.application.find("Microsoft Edge")
    if not app then return false end

    local axApp = axuielement.applicationElement(app)
    if not axApp then return false end

    local win = axApp:attributeValue("AXMainWindow")
        or axApp:attributeValue("AXFocusedWindow")
    if not win then return false end

    local target = nil

    local function walk(el, depth)
        if target or depth > 25 then return end
        local role = el:attributeValue("AXRole")
        if role == "AXWebArea" then return end -- never on the page; pruning = fast
        if role == "AXButton"
            and el:attributeValue("AXDescription") == targetDesc then
            target = el
            return
        end
        local kids = el:attributeValue("AXChildren")
        if kids then
            for _, k in ipairs(kids) do
                walk(k, depth + 1)
                if target then return end
            end
        end
    end

    walk(win, 0)

    if target then
        target:performAction("AXPress")
        return true
    end
    return false
end

local function toggleEdgeSidebar()
    local app = hs.application.frontmostApplication()
    if not app or app:name() ~= "Microsoft Edge" then return end

    -- Expanded state: "Collapse pane" exists without hover -> collapse and done.
    if pressPaneButton("Collapse pane") then return end

    -- Collapsed state: reveal the flyout with a real hover on the left edge.
    local win = app:focusedWindow()
    if not win then return end
    local f = win:frame()

    local restorePos = hs.mouse.absolutePosition()
    local outside = { x = f.x + 250, y = f.y + 200 }
    local edge    = { x = f.x + 8,   y = f.y + 200 }

    -- Enter by crossing the border (outside -> in). Just repositioning the
    -- cursor doesn't trigger hover; you must post a real mouseMoved event.
    hs.mouse.absolutePosition(outside)
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.mouseMoved, outside):post()
    hs.timer.usleep(40000)
    hs.mouse.absolutePosition(edge)
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.mouseMoved, edge):post()

    -- The flyout animates; retry until "Pin pane" exists. Pressing it pins the
    -- sidebar (expanded), so the mouse can then return.
    local attempts = 0
    local function tryPin()
        attempts = attempts + 1
        if pressPaneButton("Pin pane") then
            hs.mouse.absolutePosition(restorePos)
            return
        end
        if attempts < 15 then
            hs.timer.doAfter(0.07, tryPin)
        else
            hs.mouse.absolutePosition(restorePos) -- give up; restore the mouse
        end
    end
    hs.timer.doAfter(0.10, tryPin)
end

-- Copy the active tab's URL (Arc-style "Copy URL"). Reads from Edge's
-- AppleScript dictionary, not the address bar.
local function copyEdgeURL()
    local app = hs.application.frontmostApplication()
    if not app or app:name() ~= "Microsoft Edge" then return end

    local script = [[
        tell application "Microsoft Edge"
            try
                return URL of active tab of front window
            on error
                return ""
            end try
        end tell
    ]]
    local ok, url = hs.osascript.applescript(script)
    if ok and type(url) == "string" and url ~= "" then
        hs.pasteboard.setContents(url)
        hs.alert.show("URL copied")
    else
        hs.alert.show("Could not read the URL")
    end
end

--- EdgeArcKeys:bindHotkeys(mapping)
--- Method
--- Bind hotkeys. `mapping` keys: toggleSidebar, copyUrl; each a { {mods}, key }
--- pair. Omitted keys are left unbound. The bound hotkeys stay disabled until
--- `:start()` enables them while Edge is focused.
function obj:bindHotkeys(mapping)
    mapping = mapping or obj.defaultHotkeys
    local actions = {
        toggleSidebar = toggleEdgeSidebar,
        copyUrl       = copyEdgeURL,
    }
    -- clear any previous bindings (idempotent re-bind)
    for _, hk in ipairs(obj._hotkeys) do hk:delete() end
    obj._hotkeys = {}
    for name, action in pairs(actions) do
        local m = mapping[name]
        if m then
            table.insert(obj._hotkeys, hs.hotkey.new(m[1], m[2], action))
        end
    end
    return self
end

--- EdgeArcKeys:start()
--- Method
--- Start the app watcher that enables the bound hotkeys only while Edge is
--- focused. Call after `:bindHotkeys()`.
function obj:start()
    local function refresh(appName)
        local enable = (appName == "Microsoft Edge")
        for _, hk in ipairs(obj._hotkeys) do
            if enable then hk:enable() else hk:disable() end
        end
    end
    if obj._watcher then obj._watcher:stop() end
    obj._watcher = hs.application.watcher.new(function(name, eventType, appObj)
        if eventType == hs.application.watcher.activated then
            refresh(appObj and appObj:name() or name)
        end
    end)
    obj._watcher:start()
    -- Initial state (in case Edge is already focused on load).
    local front = hs.application.frontmostApplication()
    refresh(front and front:name() or "")
    return self
end

--- EdgeArcKeys:stop()
--- Method
--- Stop the app watcher and disable all bound hotkeys.
function obj:stop()
    if obj._watcher then
        obj._watcher:stop()
        obj._watcher = nil
    end
    for _, hk in ipairs(obj._hotkeys) do hk:disable() end
    return self
end

return obj
