#Requires AutoHotkey v2.0
#SingleInstance Force

; edge-arc-keys (Windows) — Arc/Zen-style Microsoft Edge shortcuts.
; https://github.com/gustavoguarda/edge-arc-keys
;
;   Ctrl+S        toggle the Vertical Tabs sidebar
;   Ctrl+Shift+C  copy the active tab's URL
;
; Shortcuts only apply while Edge is focused (#HotIf), so they don't swallow
; Ctrl+S ("Save") or Ctrl+Shift+C in other apps.
;
; DEPENDENCY (sidebar toggle only): the UIA-v2 library by Descolada.
;   1. Download UIA.ahk from https://github.com/Descolada/UIA-v2
;   2. Place UIA.ahk in this same folder (windows/).
; Copy-URL works without the library.
#Include *i UIA.ahk   ; *i = optional include (won't break if missing)

; ----------------------------------------------------------------------------
; Hotkeys (only while Edge is focused)
; ----------------------------------------------------------------------------
#HotIf WinActive("ahk_exe msedge.exe")

; Ctrl+Shift+C — copy the active tab's URL.
; (By default Ctrl+Shift+C opens "Inspect" in Edge; here we turn it into copy-URL.)
^+c:: CopyEdgeURL()

; Ctrl+S — toggle the Vertical Tabs sidebar.
^s:: ToggleEdgeSidebar()

#HotIf

; ----------------------------------------------------------------------------
; Copy URL — universal trick: focus the address bar, copy, restore focus.
; ----------------------------------------------------------------------------
CopyEdgeURL() {
    A_Clipboard := ""           ; clear so we can detect the copy
    Send("^l")                  ; focus the address bar (selects the URL)
    Sleep(60)
    Send("^c")                  ; copy
    copied := ClipWait(0.8)     ; wait for the clipboard to fill
    Send("{Escape}")            ; return focus to the page
    if copied
        Notify("URL copied")
    else
        Notify("Could not read the URL")
}

; ----------------------------------------------------------------------------
; Toggle the sidebar — via UI Automation.
; Expanded: "Collapse pane" exists -> collapse.
; Collapsed: "Pin pane" only appears on a left-edge hover -> hover + invoke.
; ----------------------------------------------------------------------------
ToggleEdgeSidebar() {
    if !IsSet(UIA) {
        Notify("UIA.ahk not found (required for the toggle)")
        return
    }

    try edge := UIA.ElementFromHandle(WinExist("A"))
    catch
        return

    ; Expanded state: collapse and done.
    if PressByName(edge, "Collapse pane")
        return

    ; Collapsed state: real hover on the left edge to reveal the flyout.
    WinGetPos(&wx, &wy, &ww, &wh, "A")
    DllCall("SetCursorPos", "int", wx + 250, "int", wy + 200)  ; enter from outside...
    Sleep(40)
    DllCall("SetCursorPos", "int", wx + 8,   "int", wy + 200)  ; ...into the edge strip

    ; The flyout animates; retry a few times until "Pin pane" exists.
    Loop 15 {
        Sleep(70)
        if PressByName(edge, "Pin pane")
            return
    }
}

; Find an element by Name in Edge's UIA tree and invoke it.
; Returns true if found and clicked.
PressByName(root, name) {
    try el := root.FindElement({ Name: name })
    catch
        return false
    if !el
        return false
    try {
        el.Invoke()             ; InvokePattern (buttons)
        return true
    } catch {
        try {
            el.Click()          ; fallback: click the element's center
            return true
        } catch
            return false
    }
}

; Discreet feedback (tooltip that disappears on its own).
Notify(text) {
    ToolTip(text)
    SetTimer(() => ToolTip(), -900)
}
