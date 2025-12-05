
; PS99 Clan Tracker with Big Games API - AutoHotkey v2
#Requires AutoHotkey v2.0
#SingleInstance Force

; Big Games API Configuration
API_BASE := "https://biggamesapi.io/api"
API_ENDPOINTS := Map(
    "clan", "/clan",
    "exists", "/exists"
)

; Global variables
updateInterval := 60000  ; Update every 60 seconds
clanNames := ["Goop", "fr3e", "CAT"]  ; Default clans
clanData := []
overlayVisible := true

; Create overlay GUI
CreateOverlay()

; Hotkeys
F5::ToggleOverlay()
F7::SetupClans()
F8::SetTargetWeight()
Esc::ExitApp

; Update timer
SetTimer(UpdateClanData, updateInterval)
UpdateClanData()  ; Initial update

CreateOverlay() {
    global MyGui := Gui("+AlwaysOnTop +ToolWindow", "PS99 Clan Tracker")
    MyGui.BackColor := 0x1A1A1A
    MyGui.SetFont("s12 cFFD700", "Segoe UI")
    
    MyGui.Add("Text", "Center w300", "PS99 CLAN COMPETITION")
    
    MyGui.SetFont("s10 c7DCFFF")
    global TimeText := MyGui.Add("Text", "w300", "Loading...")
    
    MyGui.SetFont("s10 c9ECE6A")
    global FirstPlace := MyGui.Add("Text", "w300", "1st: Loading...")
    
    MyGui.SetFont("s8 cWhite")
    global FirstLead := MyGui.Add("Text", "w300 x20", "Leading by: -")
    
    MyGui.SetFont("s10 cE0AF68")
    global SecondPlace := MyGui.Add("Text", "w300 x10", "2nd: Loading...")
    
    MyGui.SetFont("s8 cWhite")
    global SecondGap := MyGui.Add("Text", "w300 x20", "Points to 1st: -")
    
    MyGui.SetFont("s10 cBB9AF7")
    global ThirdPlace := MyGui.Add("Text", "w300 x10", "3rd: Loading...")
    
    MyGui.SetFont("s8 cWhite")
    global ThirdGap := MyGui.Add("Text", "w300 x20", "Points to: 2nd: - | 1st: -")
    
    MyGui.SetFont("s7 cGray")
    global LastUpdate := MyGui.Add("Text", "Right w300", "Last update: Never")
    
    MyGui.Show("x1050 y50 w320 h200")
}

UpdateClanData() {
    global clanData := []
    
    for clanName in clanNames {
        data := FetchClanData(clanName)
        if data {
            clanData.Push(data)
        }
    }
    
    ; Sort by points
    clanData := SortByPoints(clanData)
    
    ; Update display
    UpdateDisplay()
    
    ; Update timestamp
    LastUpdate.Text := "Last update: " FormatTime(, "HH:mm:ss")
}

FetchClanData(clanName) {
    try {
        url := API_BASE . API_ENDPOINTS["clan"] . "/" . clanName
        
        ; Use WinHTTP for API call
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, false)
        whr.Send()
        
        if (whr.Status = 200) {
            response := whr.ResponseText
            ; Parse JSON response (simplified)
            data := ParseClanJSON(response)
            return data
        }
    }
    return false
}

ParseClanJSON(jsonStr) {
    ; Simple JSON parsing for clan data
    ; In production, use a proper JSON library
    data := Map()
    
    ; Extract points (example pattern)
    if RegExMatch(jsonStr, '"Points"\s*:\s*(\d+)', &match) {
        data["points"] := Integer(match[1])
    }
    
    if RegExMatch(jsonStr, '"Name"\s*:\s*"([^"]+)"', &match) {
        data["name"] := match[1]
    }
    
    return data
}

SortByPoints(arr) {
    ; Bubble sort by points
    n := arr.Length
    Loop n - 1 {
        i := A_Index
        Loop n - i {
            j := A_Index
            if (arr[j]["points"] < arr[j+1]["points"]) {
                temp := arr[j]
                arr[j] := arr[j+1]
                arr[j+1] := temp
            }
        }
    }
    return arr
}

UpdateDisplay() {
    if (clanData.Length < 3) {
        TimeText.Text := "Not enough clan data"
        return
    }
    
    first := clanData[1]
    second := clanData[2]
    third := clanData[3]
    
    FirstPlace.Text := "1st: " first["name"] " - " FormatNumber(first["points"])
    FirstLead.Text := "Leading by: " FormatNumber(first["points"] - second["points"])
    
    SecondPlace.Text := "2nd: " second["name"] " - " FormatNumber(second["points"])
    SecondGap.Text := "Points to 1st: " FormatNumber(first["points"] - second["points"])
    
    ThirdPlace.Text := "3rd: " third["name"] " - " FormatNumber(third["points"])
    ThirdGap.Text := "To 2nd: " FormatNumber(second["points"] - third["points"]) 
                    . " | 1st: " FormatNumber(first["points"] - third["points"])
}

FormatNumber(num) {
    if (num >= 1000000)
        return Round(num / 1000000, 2) . "M"
    else if (num >= 1000)
        return Round(num / 1000, 1) . "K"
    else
        return num
}

ToggleOverlay() {
    global overlayVisible
    overlayVisible := !overlayVisible
    if overlayVisible
        MyGui.Show("NoActivate")
    else
        MyGui.Hide()
}

SetupClans() {
    input := InputBox("Enter clan names (comma-separated)", "Setup Clans", "w300 h100", clanNames.Join(", "))
    if input.Result = "OK" {
        global clanNames := StrSplit(input.Value, ",")
        for i, name in clanNames {
            clanNames[i] := Trim(name)
        }
        UpdateClanData()
    }
}

SetTargetWeight() {
    input := InputBox("Enter target weight (kg)", "Target Weight", "w200 h100", "3200")
    if input.Result = "OK" {
        ; Store target weight (can be used for tracking)
        MsgBox("Target weight set to: " input.Value . "kg")
    }
}
