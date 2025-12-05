
; PS99 Auto Dice Roller - Converted to AutoHotkey v2
#Requires AutoHotkey v2.0
#SingleInstance Force

; Configuration
rollDelay := 100
isActive := false

F1:: {
    global isActive
    isActive := !isActive
    
    if (isActive) {
        if WinExist("ahk_exe RobloxPlayerBeta.exe") {
            WinActivate
            ToolTip("Auto Dice Roller: ON")
            AutoRoll()
        } else {
            isActive := false
            ToolTip("Roblox not found!")
        }
    } else {
        ToolTip("Auto Dice Roller: OFF")
    }
    SetTimer(() => ToolTip(), -2000)
}

AutoRoll() {
    global isActive, rollDelay
    
    while (isActive && WinActive("ahk_exe RobloxPlayerBeta.exe")) {
        ; Click dice roll positions (adjust coordinates for 1920x1080)
        Click(601, 451)
        Sleep(rollDelay)
        Click(968, 447)
        Sleep(rollDelay)
        Click(1315, 453)
        Sleep(rollDelay)
        Click(595, 698)
        Sleep(rollDelay)
        Click(962, 699)
        Sleep(rollDelay)
        Click(1323, 697)
        Sleep(rollDelay)
        
        ; Anti-kick movement
        Send("{s down}")
        Sleep(1000)
        Send("{s up}")
        Sleep(64)
        Send("{w down}")
        Sleep(1000)
        Send("{w up}")
        Sleep(10)
    }
}

F2::ExitApp
