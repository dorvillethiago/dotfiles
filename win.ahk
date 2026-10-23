#Requires AutoHotkey v2.0
#SingleInstance Force

~LWin:: {
    Send "{Blind}{vkE8}"   ; stop start menu
    KeyWait "LWin"         ; waits for letting go of windows key
    if (A_PriorKey = "LWin")  ; no other key pressed
        Send "#!{Space}"
}

; FL Studio drags its own window without firing EVENT_SYSTEM_MOVESIZEEND,
; so komorebi never sees the drag finish. Retile on mouse release instead.
global flHwnd := 0, flPos := ""

~LButton:: {
    global flHwnd, flPos
    flHwnd := 0
    MouseGetPos , , &hwnd
    if (hwnd && WinGetClass(hwnd) = "TFruityLoopsMainForm") {
        WinGetPos &x, &y, &w, &h, hwnd
        flHwnd := hwnd, flPos := x "," y "," w "," h
    }
}

~LButton Up:: {
    global flHwnd, flPos
    if (!flHwnd || !WinExist(flHwnd))
        return
    hwnd := flHwnd, flHwnd := 0
    WinGetPos &x, &y, &w, &h, hwnd
    if (x "," y "," w "," h != flPos)
        Run "komorebic retile", , "Hide"
}