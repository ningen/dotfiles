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
    global InitialHeight
    WinShow(WinTitle)
    WinActivate(WinTitle)
    WinGetPos(&CurX, &CurY, &CurWidth, &CurHeight, WinTitle)
    if IsInit {
        WinMove(XPosCorrection, YPosCorrection, A_ScreenWidth + Abs(YPosCorrection * 2), InitialHeight)
    } else {
        WinMove(XPosCorrection, YPosCorrection, A_ScreenWidth + Abs(YPosCorrection * 2), CurHeight)
    }
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
        Run(AppCommand)
        if WinWait(WinClassTitle,,5)
            Hwnd := WinExist(WinClassTitle)
        else {
            MsgBox("Timeout waiting for " AppCommand "!")
            Return
        }
    }
    WinIdTitle := "ahk_id " Hwnd
    WinSetAlwaysOnTop(1, WinIdTitle)
    WinSetTransparent(Opacity, WinIdTitle)
    WinSetStyle(-0x800000, WinIdTitle)
    return WinIdTitle
}

ToggleTerminal() {
    static WinIdTitle := ""
    DetectHiddenWindows true
    if !WinExist(WinIdTitle) {
        WinIdTitle := FindOrRunApp()
        ShowAndPositionTerminal(WinIdTitle)
        return
    }
    DetectHiddenWindows false
    if WinExist(WinIdTitle) {
        if !IsInit
            WinHide(WinIdTitle)
        ActiveTitle := WinExist("A")
        if !ActiveTitle {
            Send "{Blind}!{Esc}"
        }
    } else {
        ShowAndPositionTerminal(WinIdTitle)
    }
}
