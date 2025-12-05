; PS99 Auto Hatch - AutoHotkey v2
#Requires AutoHotkey v2.0
#SingleInstance Force

; Global variables
global speed := 40
global BetweenHatchSpeed := 50
global Colorcheck := 0x121215

; GUI coordinates
coords := Map(
    "AutoHatchSettingsX", 0,
    "AutoHatchSettingsY", 0,
    "AutoHatchXX", 0,
    "AutoHatchXY", 0,
    "AutoHatchONX", 0,
    "AutoHatchONY", 0,
    "EggEButtonX", 0,
    "EggEButtonY", 0,
    "HatchEButtonX", 0,
    "HatchEButtonY", 0,
    "FriendsBarX", 0,
    "FriendsBarY", 0
)

; Create GUI
MyGui := Gui()
MyGui.Title := "PS99 Auto Hatch Setup"

; Add buttons and inputs for each coordinate
buttons := [
    {label: "Auto Hatch Settings", desc: "Click the Auto Hatch Settings button"},
    {label: "Auto Hatch X", desc: "Click the X to close button"},
    {label: "Auto Hatch ON", desc: "Click the Auto Hatch toggle"},
    {label: "Egg E Button", desc: "Click the Egg E key location"},
    {label: "Open Egg Button", desc: "Click the hatch location"},
    {label: "Friends Bar", desc: "Click the black area of Friends Bar"}
]

yPos := 20
for index, btn in buttons {
    MyGui.Add("Button", "x20 y" yPos " w150 h25", btn.label).OnEvent("Click", SaveCoord)
    MyGui.Add("Edit", "x180 y" yPos " w60 h25 vX" index)
    MyGui.Add("Edit", "x250 y" yPos " w60 h25 vY" index)
    yPos += 35
}

yPos += 10
StartBut := MyGui.Add("Button", "x100 y" yPos " w120 h30", "Start Macro")
StartBut.OnEvent("Click", StartMacro)

LoadSettings()
MyGui.Show("w350 h" (yPos + 40))


; ========== COORD SAVE FUNCTION ==========
SaveCoord(btn, *) {
    global coords, MyGui, buttons
    MsgBox("Please click the position for: " btn.Text, "Position Setup", 0)
    KeyWait("LButton", "D")
    MouseGetPos(&x, &y)
    
    ; Find the index of the clicked button to correctly map coordinates
    buttonIndex := 0
    for index, b in buttons {
        if b.label = btn.Text {
            buttonIndex := index
            break
        }
    }

    if (buttonIndex > 0) {
        xVarName := "X" buttonIndex
        yVarName := "Y" buttonIndex
        
        MyGui[xVarName].Value := x
        MyGui[yVarName].Value := y
        MsgBox("Saved: X=" x ", Y=" y)
    } else {
        MsgBox("Error: Could not determine which coordinate to save.")
    }
}

StartMacro(*) {
    global StartBut
    StartBut.Text := "Macro Running"
    if !WinExist("ahk_exe RobloxPlayerBeta.exe") {
        MsgBox("Roblox not running!")
        return
    }
    WinActivate("ahk_exe RobloxPlayerBeta.exe")
    MainLoop()
}

MainLoop() {
    global speed, BetweenHatchSpeed, Colorcheck, MyGui
    
    ToolTip("Auto Hatch Running - Press F2 to stop")
    
    ; Retrieve coordinates from GUI edits
    hatchbuttonX := MyGui["X1"].Value
    hatchbuttonY := MyGui["Y1"].Value
    autohatchposX := MyGui["X3"].Value
    autohatchposY := MyGui["Y3"].Value
    Xbuttonpos := [MyGui["X2"].Value, MyGui["Y2"].Value]
    EggEButtonPos := [MyGui["X4"].Value, MyGui["Y4"].Value]
    HatchEButtonPos := [MyGui["X5"].Value, MyGui["Y5"].Value]
    FriendsBarX := MyGui["X6"].Value
    FriendsBarY := MyGui["Y6"].Value

    Loop {
        color := PixelGetColor(FriendsBarX, FriendsBarY)

        if (color = Colorcheck) {
            SendEvent("{Tab}")
            Sleep(200)
            SendEvent("{Click " hatchbuttonX " " hatchbuttonY " 1}")
            Sleep(200)
            SendEvent("{Click " autohatchposX " " autohatchposY " 1}")
            Sleep(200)
            SendEvent("{Click " Xbuttonpos[1] " " Xbuttonpos[2] " 1}")
        }

        SendEvent("{Click " EggEButtonPos[1] " " EggEButtonPos[2] " 0}")
        Sleep(10)
        SendEvent("{Click " EggEButtonPos[1] + 5 " " EggEButtonPos[2] " 1}")
        Sleep(speed)

        SendEvent("{Click " HatchEButtonPos[1] " " HatchEButtonPos[2] " 0}")
        Sleep(10)
        SendEvent("{Click " HatchEButtonPos[1] + 5 " " HatchEButtonPos[2] " 1}")

        Sleep(BetweenHatchSpeed)
    }
}

SaveSettings() {
    global MyGui, buttons
    iniFile := "ps99_settings.ini"

    for index, btn in buttons {
        xKey := "X" index
        yKey := "Y" index
        xVal := MyGui[xKey].Value
        yVal := MyGui[yKey].Value

        IniWrite(xVal, iniFile, "Coords", xKey)
        IniWrite(yVal, iniFile, "Coords", yKey)
    }
}

LoadSettings() {
    global MyGui, buttons
    iniFile := "ps99_settings.ini"

    if FileExist(iniFile) {
        for index, btn in buttons {
            xKey := "X" index
            yKey := "Y" index

            xVal := IniRead(iniFile, "Coords", xKey, "0")
            yVal := IniRead(iniFile, "Coords", yKey, "0")

            MyGui[xKey].Value := xVal
            MyGui[yKey].Value := yVal
        }
    }
}

MyGui_Close(*) {
    if MsgBox("Are you sure you want to close the GUI?", "Confirm Close", "y/n") = "No"
        return true
    else {
        SaveSettings()
        ExitApp()
    }
}

OnExit(funcOnExit) {
    SaveSettings()
}

F2::ExitApp()