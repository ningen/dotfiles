#Requires AutoHotkey v2.0

; App settings
AppCommand := "wezterm-gui"
AppClass := "org.wezfurlong.wezterm"

; Window settings
Opacity := 225
InitialHeight := A_ScreenHeight * 0.4
IsInit := false
XPosCorrection := -8
YPosCorrection := -8

; Hotkey: Ctrl+I to toggle WezTerm
Control & i:: {
    ToggleTerminal()
}

ShowAndPositionTerminal(WinTitle) {
    global InitialHeight, XPosCorrection, YPosCorrection
    
    ; Validate window exists before attempting to get position
    if !WinExist(WinTitle) {
        return false
    }
    
    try {
        WinGetPos(&CurX, &CurY, &CurWidth, &CurHeight, WinTitle)
        
        ; Double-check window still exists after getting position
        if !WinExist(WinTitle) {
            return false
        }
        
        if IsInit {
            WinMove(XPosCorrection, YPosCorrection, A_ScreenWidth + Abs(YPosCorrection * 2), InitialHeight, WinTitle)
        } else {
            WinMove(XPosCorrection, YPosCorrection, A_ScreenWidth + Abs(YPosCorrection * 2), CurHeight, WinTitle)
        }
        
        ; Validate window still exists before showing
        if WinExist(WinTitle) {
            WinShow(WinTitle)
            WinActivate(WinTitle)
            return true
        }
        
    } catch Error as e {
        ; Silent error handling to avoid disrupting user experience
        return false
    }
    
    return false
}

FindAppWindow() {
    global AppClass
    DetectHiddenWindows true
    WinClassTitle := "ahk_class " AppClass
    Hwnd := WinExist(WinClassTitle)
    DetectHiddenWindows false
    return Hwnd
}

FindOrRunApp() {
    global AppCommand, Opacity, AppClass
    WinClassTitle := "ahk_class " AppClass
    Hwnd := FindAppWindow()
    if !Hwnd {
        IsInit := true
        try {
            Run(AppCommand)
            if WinWait(WinClassTitle,,5)
                Hwnd := WinExist(WinClassTitle)
            else {
                MsgBox("Timeout waiting for " AppCommand "!")
                Return
            }
        } catch Error as e {
            MsgBox("Failed to run " AppCommand ": " e.message)
            Return
        }
    }
    
    ; Validate that we have a valid window handle
    if !Hwnd {
        MsgBox("Failed to get valid window handle for " AppCommand)
        Return
    }
    
    WinIdTitle := "ahk_id " Hwnd
    
    ; Validate window exists before applying properties
    if !WinExist(WinIdTitle) {
        MsgBox("Target window not found: " WinIdTitle)
        Return
    }
    
    try {
        WinSetAlwaysOnTop(1, WinIdTitle)
        WinSetTransparent(Opacity, WinIdTitle)
        WinSetStyle(-0x800000, WinIdTitle)
    } catch Error as e {
        MsgBox("Failed to apply window properties: " e.message)
        Return
    }
    
    return WinIdTitle
}

ToggleTerminal() {
    static WinIdTitle := ""
    
    try {
        DetectHiddenWindows true
        if !WinExist(WinIdTitle) {
            WinIdTitle := FindOrRunApp()
            if !WinIdTitle {
                ; Failed to get valid window, exit early
                return
            }
            if !ShowAndPositionTerminal(WinIdTitle) {
                ; Failed to position window, reset and try again
                WinIdTitle := ""
                return
            }
            return
        }
        
        DetectHiddenWindows false
        if WinExist(WinIdTitle) {
            if !IsInit {
                try {
                    WinHide(WinIdTitle)
                } catch Error {
                    ; Window might have been closed, reset the stored ID
                    WinIdTitle := ""
                    return
                }
            }
            
            try {
                ActiveTitle := WinExist("A")
                if !ActiveTitle {
                    Send "{Blind}!{Esc}"
                }
            } catch Error {
                ; Ignore errors in fallback activation
            }
        } else {
            ; Window no longer exists, clear stored ID and find/run app again
            WinIdTitle := ""
            NewWinIdTitle := FindOrRunApp()
            if NewWinIdTitle {
                WinIdTitle := NewWinIdTitle
                ShowAndPositionTerminal(WinIdTitle)
            }
        }
    } catch Error as e {
        ; Reset state on any unexpected error
        WinIdTitle := ""
    }
}
