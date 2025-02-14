#Requires AutoHotkey v2.1-alpha.16
#SingleInstance Force
#Include AHKHID.ahk

script_title := "KBLayerHelper"
script_version := "17/01/2023"
script_author := "Raph.Coder"
global script_ini := A_ScriptDir "\" script_title ".ini"

; defining of global variables
SetWorkingDir(A_ScriptDir)

global VendorId := 16715
global ProductId := 1
global DisplayLayout := 0
global LayoutSize := []
global LayoutPosition := []
global LayoutFontSize := 20
global LayoutDuration := 1000
global LayoutTransparency := 128
global DisplayLayerName := 0
global LayerNameSize := []
global LayerNamePosition := []
global LayerNameFontSize := 20
global LayerNameDuration := 1000
global LayerNameTransparency := 128
global NoDisplayTimeout := 0
global LockHotKey := "!NumLock"
global LayoutDisplayHotKey := "+^!#d"
global MomentaryLayoutDisplayHotKey := "+^!#f"
global MomentaryLayoutDisplayDuration := 1000
global MomentaryTimerRunning := 0
global indicatorLayer := Gui()
global layoutLayer := Gui()
global LayerArray := Map() ; Initialize as a Map object ; - harmy
global DEFAULT_ICON_PATH := "./icons/ico/default.ico" ; Define default icon path - harmy

; Ini file read
ReadIniFile()

; Set tray icon of layer 0
SetTrayIcon(LayerArray[0].ico)

; Set hotkey to disable timeout
Hotkey(LockHotKey, ChangeNoDisplayTimeout, "on")
Hotkey(LayoutDisplayHotKey, ChangeDisplayLayout, "on")
Hotkey(MomentaryLayoutDisplayHotKey, MomentaryLayoutDisplay, "on")

; Construct tray icon menu
A_TrayMenu.Add("Show Layout", ChangeDisplayLayout)
A_TrayMenu.Add("Show Layer Name", ChangeDisplayLayerName)
A_TrayMenu.Add("No timeout", ChangeNoDisplayTimeout)

A_TrayMenu.Add() ; separator
A_TrayMenu.Add("Reload " script_title, (*) => Reload())
A_TrayMenu.Add("Exit " script_title, (*) => ExitApp())

if DisplayLayout
    A_TrayMenu.Check("Show Layout")

if DisplayLayerName
    A_TrayMenu.Check("Show Layer Name")

if NoDisplayTimeout
    A_TrayMenu.Check("No timeout")

AHKHID_UseConstants()
usagePage := 65329
usage := 116

mainGUI := Gui()
GuiHandle := mainGUI.Hwnd  ; Retrieve the GUI handle correctly

; Intercept WM_INPUT
OnMessage(0x00FF, InputMsg.Bind(), 1)

AHKHID_Register(usagePage, usage, GuiHandle, RIDEV_INPUTSINK)

mainGUI.Show()

        ; included by harmy
    ImageGetSize(imagePath, width, height) {
    if !FileExist("./icons/ico/default.ico") {
    MsgBox("File not found: ./icons/ico/default.ico")
}

    ; Read the binary data of the file
    FileRead imgData, imagePath
    if (SubStr(imgData, 1, 8) != Chr(137) "PNG" Chr(13) Chr(10) Chr(26) Chr(10)) {
        MsgBox("Not a valid PNG file: " imagePath)
        return false
}

    ; PNG width and height are stored in bytes 17-24
    width := NumGet(&imgData, 16, "UInt")
    height := NumGet(&imgData, 20, "UInt")
    return true
}

    ; Define the function for handling input messages
    InputMsg(wParam, lParam) {
    ; Your WM_INPUT handling logic here
}

; Function to set the tray icon
SetTrayIcon(iconPath) {
    if FileExist(iconPath) {
        A_TrayMenu.SetIcon(iconPath)  ; Use A_TrayMenu.SetIcon() to set the tray icon
    } else {
        A_TrayMenu.SetIcon(DEFAULT_ICON_PATH)  ; Fallback to the default icon
    }
}

; Function to read the ini file
ReadIniFile() {
    VendorId := IniRead(script_ini, "Device", "VendorId", 16715)
    ProductId := IniRead(script_ini, "Device", "ProductId", 1)

    NoDisplayTimeout := IniRead(script_ini, "General", "NoDisplayTimeout", 0)
    LockHotKey := IniRead(script_ini, "General", "LockHotKey", "!NumLock")
    LayoutDisplayHotKey := IniRead(script_ini, "General", "LayoutDisplayHotKey", "+^!#d")
    MomentaryLayoutDisplayHotKey := IniRead(script_ini, "General", "MomentaryLayoutDisplayHotKey", "+^!#f")
    MomentaryLayoutDisplayDuration := IniRead(script_ini, "General", "MomentaryLayoutDisplayDuration", 1000)

    DisplayLayout := IniRead(script_ini, "Layout", "DisplayLayout", 1)
    inipos := IniRead(script_ini, "Layout", "Position", "center,-50")
    LayoutPosition := StrSplit(inipos, ",", " `t")
    inisize := IniRead(script_ini, "Layout", "Size", "300,200")
    LayoutSize := StrSplit(inisize, ",", " `t")
    LayoutFontSize := IniRead(script_ini, "Layout", "FontSize", 20)
    LayoutTransparency := IniRead(script_ini, "Layout", "Transparency", 128)
    LayoutDuration := IniRead(script_ini, "Layout", "Duration", 1000)

    DisplayLayerName := IniRead(script_ini, "LayerName", "DisplayLayerName", 1)
    inipos := IniRead(script_ini, "LayerName", "Position", "center,-50")
    LayerNamePosition := StrSplit(inipos, ",", " `t")
    inisize := IniRead(script_ini, "LayerName", "Size", "200,50")
    LayerNameSize := StrSplit(inisize, ",", " `t")
    LayerNameFontSize := IniRead(script_ini, "LayerName", "FontSize", 20)
    LayerNameDuration := IniRead(script_ini, "LayerName", "Duration", 1000)
    LayerNameTransparency := IniRead(script_ini, "LayerName", "Transparency", 128)

    LayerArray.Clear()  ; Clear the contents of the Map while preserving its type

    ; Read all Layers section
    outputVarSection := IniRead(script_ini, "Layers")

    For array_idx, layerLine in StrSplit(outputVarSection, "`n", " `t") {
        idx := array_idx - 1

        ; Ensure layerLine is not empty
        if layerLine != "" {
            ; Split the line into an array
            cur_LayerArray := StrSplit(layerLine, ",", " `t")

            ; Ensure cur_LayerArray is an array and has the expected elements
            if IsObject(cur_LayerArray) && cur_LayerArray.Length >= 4 {
                layerRef := (Trim(cur_LayerArray[1]) != "") ? Trim(cur_LayerArray[1]) : Format("{:01}", idx)
                label := (Trim(cur_LayerArray[2]) != "") ? Trim(cur_LayerArray[2]) : "Layer " layerRef
                ico := (Trim(cur_LayerArray[3]) != "") ? Trim(cur_LayerArray[3]) : DEFAULT_ICON_PATH
                image := (Trim(cur_LayerArray[4]) != "") ? Trim(cur_LayerArray[4]) : "./png/default.png"

                ; Validate file paths
                if !FileExist(ico) {
                    MsgBox("Icon file not found: " ico)
                    ico := DEFAULT_ICON_PATH
            }
            if !FileExist(image) {
                MsgBox("Image file not found: " image)
                image := "./png/default.png"
}

                ; Assign values to LayerArray
                LayerArray[layerRef] := {label: label, ico: ico, image: image}
            } else {
                ; Log an error or skip invalid lines
                MsgBox("Invalid layerLine or missing elements: " layerLine)
                continue
            }
        }
    }

    ; Ensure LayerArray[0] exists with default values if not already populated
    if !LayerArray.Has(0) {
        LayerArray[0] := {
            label: "Default Layer",
            ico: DEFAULT_ICON_PATH,
            image: "./png/default.png"
    }
}

    ; Debugging: Log the contents of LayerArray
    for key, value in LayerArray {
        MsgBox("Layer Key: " key "`nLabel: " value.label "`nIcon: " value.ico "`nImage: " value.image)
    }
}

    ; Set the tray icon for Layer 0
    SetTrayIcon(LayerArray[0].ico)

    ; Debugging: Log the contents of LayerArray
    for key, value in LayerArray {
        MsgBox("Layer Key: " key "`nLabel: " value.label "`nIcon: " value.ico "`nImage: " value.image)
    }

ComputePosition(ix, iy, width, height, &x, &y) {
    if (ix = "center")
        x := A_ScreenWidth/2 - width/2
    else
        x := ix < 0 ? A_ScreenWidth - width + ix : ix

    if (iy = "center")
        y := A_ScreenHeight/2 - height/2
    else
        y := iy < 0 ? A_ScreenHeight - height + iy : iy
}

ShowLayoutOSD(key, image) {
    static layoutNameID, layoutPicture
    width := LayoutSize[1]
    height := LayoutSize[2]

    if !WinExist("layoutGUI") {
        layoutLayer := Gui()
        layoutLayer.MarginX := 0
        layoutLayer.MarginY := 0

        oWidth := width
        oHeight := height
        if (FileExist(image)) {
        ogclayoutPicture := layoutLayer.Add("Picture", "vlayoutPicture AltSubmit BackgroundTrans", image)
        myPict := ogclayoutPicture.Hwnd

        ; Get the dimensions of the image
        ImageGetSize(image, &iWidth, &iHeight)

        if (iWidth / iHeight > oWidth / oHeight)
            oHeight := width * iHeight / iWidth
        else
            oWidth := height * iWidth / iHeight

        ogclayoutPicture.Move(width / 2 - oWidth / 2, height - oHeight, oWidth, oHeight)
}

        layoutLayer.SetFont("s" LayoutFontSize " cBlack", "Verdana")
        ogcTextlayoutNameID := layoutLayer.Add("Text", "y0 x0 w" width " h" height " BackGroundTrans Center vlayoutNameID", key)
    }
    else {
        ogcTextlayoutNameID.Text := key
        if (FileExist(image))
            ogclayoutPicture.Value := image
    }

    ComputePosition(LayoutPosition[1], LayoutPosition[2], width, height, &xPlacement, &yPlacement)

    if (FileExist(image)) {
        layoutLayer.Show("x" xPlacement " y" yPlacement " NoActivate AutoSize")
        WinSetExStyle(layoutLayer.Hwnd, 32)
        WinSetTransparent(LayoutTransparency, layoutLayer.Hwnd)

        SetTimer(HideLayoutOSD, -LayoutDuration)
        if (MomentaryTimerRunning)
            SetTimer(StopMomentaryDisplay, -MomentaryLayoutDisplayDuration)
    }
    else
        HideLayoutOSD()
}

ShowLayerNameOSD(key) {
    static layerNameTxtID, layerNamePictureID
    width := LayerNameSize[1]
    height := LayerNameSize[2]

    ComputePosition(LayerNamePosition[1], LayerNamePosition[2], width, height, &xPlacement, &yPlacement)

    if !WinExist("layerGUI") {
        indicatorLayer := Gui()
        indicatorLayer.BackColor := "FF0000"
        indicatorLayer.MarginX := 0
        indicatorLayer.MarginY := 0

        indicatorLayer.SetFont("s" LayerNameFontSize " cWhite", "Verdana")
        ogcTextlayerNameTxtID := indicatorLayer.Add("Text", "x0 y0 w" width " h" height " BackGroundTrans Center vlayerNameTxtID", key)
    }
    else {
        ogcTextlayerNameTxtID.Text := key
    }

    indicatorLayer.Show("x" xPlacement " y" yPlacement " NoActivate AutoSize")
    WinSetExStyle(indicatorLayer.Hwnd, 32)
    WinSetTransparent(LayerNameTransparency, indicatorLayer.Hwnd)

    SetTimer(HideLayerNameOSD, -LayerNameDuration)
}

HideLayoutOSD() {
    if (!NoDisplayTimeout)
        layoutLayer.Hide()
    SetTimer(HideLayoutOSD, 0)
}

HideLayerNameOSD() {
    if (!NoDisplayTimeout)
        indicatorLayer.Hide()
    SetTimer(HideLayerNameOSD, 0)
}

MomentaryLayoutDisplay() {
    if (!DisplayLayout) {
        SetTimer(StopMomentaryDisplay, -MomentaryLayoutDisplayDuration)
        DisplayLayout := 1
        MomentaryTimerRunning := 1
    }
}

StopMomentaryDisplay() {
    SetTimer(StopMomentaryDisplay, 0)
    if (MomentaryTimerRunning)
        DisplayLayout := 0
    MomentaryTimerRunning := 0
}

ChangeDisplayLayout() {
    if (DisplayLayout) {
        DisplayLayout := 0
        A_TrayMenu.UnCheck("Show Layout")
    }
    else {
        DisplayLayout := 1
        A_TrayMenu.Check("Show Layout")
    }
    IniWrite(DisplayLayout, script_ini, "Layout", "DisplayLayout")
}

ChangeDisplayLayerName() {
    if (DisplayLayerName) {
        DisplayLayerName := 0
        A_TrayMenu.UnCheck("Show Layer Name")
    }
    else {
        DisplayLayerName := 1
        A_TrayMenu.Check("Show Layer Name")
    }
    IniWrite(DisplayLayerName, script_ini, "LayerName", "DisplayLayerName")
}

ChangeNoDisplayTimeout() {
    if (NoDisplayTimeout) {
        NoDisplayTimeout := 0
        indicatorLayer := Gui()
        indicatorLayer.Hide()
        layoutLayer := Gui()
        layoutLayer.Hide()
        A_TrayMenu.UnCheck("No timeout")
    }
    else {
        NoDisplayTimeout := 1
        A_TrayMenu.Check("No timeout")
    }
    IniWrite(NoDisplayTimeout, script_ini, "General", "NoDisplayTimeout")
}