#Requires AutoHotkey v2.0
#SingleInstance Force

~LWin:: {
    Send "{Blind}{vkE8}"   ; stop start menu
    KeyWait "LWin"         ; waits for letting go of windows key
    if (A_PriorKey = "LWin")  ; no other key pressed
        Send "#!{Space}"
}  