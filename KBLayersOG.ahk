; V1toV2: Removed #NoEnv
#SingleInstance Force

script_title	:= "KBLayerHelper"
script_version	:= "17/01/2023"
script_author	:= "Raph.Coder"
global script_ini		:= A_ScriptDir "\" script_title ".ini"



; V1toV2: Removed SetBatchLines, -1
SetWorkingDir(A_ScriptDir)



global VendorId, ProductId
global DisplayLayout, LayoutSize, LayoutPosition, LayoutFontSize, LayoutDuration, LayoutTransparency
global DisplayLayerName, LayerNameSize, LayerNamePosition, LayerNameFontSize, LayerNameDuration, LayerNameTransparency
global NoDisplayTimeout, LockHotKey, LayerArray, LayoutDisplayHotKey
global MomentaryLayoutDisplayHotKey, MomentaryLayoutDisplayDuration, MomentaryTimerRunning

MomentaryTimerRunning := 0

; Ini file read
ReadIniFile()

; Set hotkey to disable timeout
Hotkey(LockHotKey, ChangeNoDisplayTimeout, "on")
Hotkey(LayoutDisplayHotKey, ChangeDisplayLayout, "on")
Hotkey(MomentaryLayoutDisplayHotKey, MomentaryLayoutDisplay, "on")

; Construct tray icon menu
Tray.Delete() ; V1toV2: not 100% replacement of NoStandard, Only if NoStandard is used at the beginning
Tray.Add("Show Layout", ChangeDisplayLayout)
Tray.Add("Show Layer Name", ChangeDisplayLayerName)
Tray.Add("No timeout", ChangeNoDisplayTimeout)

Tray.Add() ; seperator
Tray.Add("Reload " . script_title, Reload)
Tray.Add("Exit " . script_title, Exit)


if DisplayLayout
    Tray.Check("Show Layout")

if DisplayLayerName
    Tray.Check("Show Layer Name")

if NoDisplayTimeout
    Tray.Check("No timeoutr")


;Set up the constants
AHKHID_UseConstants()
usagePage := 65329
usage := 116

mainGUI := Gui()
GuiHandle := WinExist()

;Intercept WM_INPUT
OnMessage(0x00FF, InputMsg, 1)

AHKHID_Register(usagePage, usage, GUIHANDLE, RIDEV_INPUTSINK)

mainGUI.Show()
; Set tray icon of layer 0
SetTrayIcon(LayerArray[0].ico)
Return


ReadIniFile()
{
        local tmpLayer, curArray, curObj
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

    LayerArray := [{}]

    ; Read all Layers section
    outputVarSection := IniRead(script_ini, "Layers")

    For array_idx, layerLine in StrSplit(outputVarSection, "`n", " `t")
    {
        local idx, cur_LayerArray
        idx := array_idx - 1

        ; Remove the 'key='' in front of the line by looking for the first =
        ; Search for =
        pos := InStr(layerLine, "=")
        if (pos > 0)
        {
            layerLine := SubStr(layerLine, (pos+1)<1 ? (pos+1)-1 : (pos+1))

            ; Split line with ,

            cur_LayerArray := StrSplit(layerLine , ",", " `t")


            layerRef := Trim(cur_LayerArray[1]) ? Trim(cur_LayerArray[1]) : Format("{:01}", idx)
            ; Layer name
            cur_LayerArray[2] := Trim(cur_LayerArray[2]) ? Trim(cur_LayerArray[2]) : "Layer " layerRef
            ; Layer icon
            cur_LayerArray[3] := Trim(cur_LayerArray[3]) ? Trim(cur_LayerArray[3]) : "./icons/ico/Number-" layerRef ".ico"
            ; Layer image
            cur_LayerArray[4] := Trim(cur_LayerArray[4]) ? Trim(cur_LayerArray[4]) : "./png/Layer-" layerRef ".png"

            LayerArray[layerRef] := {label:cur_LayerArray[2], ico:cur_LayerArray[3], image:cur_LayerArray[4]}
        }

    }

}


InputMsg(wParam, lParam, msg, hwnd) {
    Local r, H
    Local iVendorID, iProductID, data, mystring
    Critical()


    r := AHKHID_GetInputInfo(lParam, II_DEVTYPE)

    If(r = RIM_TYPEHID){
        h := AHKHID_GetInputInfo(lParam, II_DEVHANDLE)
        r := AHKHID_GetInputData(lParam, uData)
        offset := 0x1


        iVendorID := AHKHID_GetDevInfo(h, DI_HID_VENDORID,     True)
        iProductID :=  AHKHID_GetDevInfo(h, DI_HID_PRODUCTID,    True)
        If(iVendorID == VendorId)
        ; If(iVendorID == VendorId and iProductID == ProductId)
        {
            orgString:
            mystring := Trim(StrGet(&uData + offset, "UTF-8"), OmitChars := "`t`n`r")
            Loop Parse, mystring, "`n", "`r"
            {
                foundPos := InStr(A_LoopField, "KBHLayer")
                If(foundPos>0){

                    idx := SubStr(A_LoopField, (8+foundPos)<1 ? (8+foundPos)-1 : (8+foundPos))
                    SetTrayIcon(LayerArray[idx].ico)

                    If (DisplayLayout)
                        ShowLayoutOSD(LayerArray[idx].label, LayerArray[idx].image)
                    If (DisplayLayerName)
                        ShowLayerNameOSD(LayerArray[idx].label)

                }
            }
        }
    }
    return
}


SetTrayIcon(iconname){
    If FileExist(iconname)
        TraySetIcon(iconname)
}

ShowLayerNameOSD(key){
    static layerNameTxtID, layerNamePictureID

    width := LayerNameSize.1
    height := LayerNameSize.2

    ComputePosition(LayerNamePosition.1,  LayerNamePosition.2,  width,  height, &xPlacement, &yPlacement)


    if !WinExist("layerGUI")
    {
        
        indicatorLayer.BackColor := "FF0000"
        indicatorLayer.MarginX := "0", indicatorLayer.MarginY := "0"

        ; Gui, indicatorLayer:Add, Picture, x0 y0 w%width% h%height% vlayerNamePictureID AltSubmit BackgroundTrans , ./png/LayerBox.png
        indicatorLayer.SetFont("s" . LayerNameFontSize . " cWhite", "Verdana")
        ogcTextlayerNameTxtID := indicatorLayer.Add("Text", "x0 y0 w" . width . " h" . height . " BackGroundTrans Center vlayerNameTxtID", key)
    }
    else
    {
        ogcTextlayerNameTxtID.Text := key
    }


    indicatorLayer.Show("x" . xPlacement . " y" . yPlacement . " NoActivate  AutoSize")
    WinSetExStyle(32)
    ; WinSet, TransColor, FFFFFF 64
    WinSetTransparent(LayerNameTransparency)

    SetTimer(HideLayerNameOSD,-%LayerNameDuration%)

}

 ShowLayoutOSD(key, image){
    static layoutNameID
    static layoutPicture

    width := LayoutSize.1
    height := LayoutSize.2

    If !WinExist("layoutGUI")
    {
        
        layoutLayer.MarginX := "0", layoutLayer.MarginY := "0"

        oWidth := width
        oHeight := height
        if( FileExist(image))
        {
            static picture

            ogclayoutPicture := layoutLayer.Add("Picture", "vlayoutPicture  AltSubmit BackgroundTrans", image)
            myPict := ogclayoutPicture.hwnd

            ControlGetPos(, , &iWidth, &iHeight, , "ahk_id " myPict)

            if(iWidth / iHeight > oWidth/oHeight)
                oHeight := width*iHeight/iWidth
            Else
                oWidth := height*iWidth/iHeight


            ogclayoutPicture.Move(width/2-oWidth/2, height-oHeight, oWidth, oHeight)

        }



        layoutLayer.SetFont("s" . LayoutFontSize . " cBlack", "Verdana")
        ogcTextlayoutNameID := layoutLayer.Add("Text", "y0 x0 w" . width . " h" . height . " BackGroundTrans Center vlayoutNameID", key)
    }
    Else{
        ; OutputDebug, REUSE - %layoutNameID% - %layoutPicture%
        ogcTextlayoutNameID.Text := key
        if( FileExist(image))
            ogclayoutPicture.Value := image

    }


    ComputePosition(LayoutPosition.1,  LayoutPosition.2,  width,  height, &xPlacement, &yPlacement)

    if (FileExist(image)){
        layoutLayer.Show("x" . xPlacement . " y" . yPlacement . "  NoActivate AutoSize")
        WinSetExStyle(32)
        WinSetTransparent(LayoutTransparency)

        SetTimer(HideLayoutOSD,-%LayoutDuration%)
        if(MomentaryTimerRunning)
            SetTimer(StopMomentaryDisplay,-%MomentaryLayoutDisplayDuration%)

    }
    Else
        HideLayoutOSD()

}

; Calculate OSD screen position
; if position >= 0 : from top/left of the screen
; if position < 0 : from bottom/right
; 'center' to center OSD on screen
ComputePosition(ix, iy, width, height, &x, &y)
{
    if(ix = "center")
    {
        x := % A_ScreenWidth/2 - width/2
    }
    else{
        if(ix < 0)
            x := % A_ScreenWidth - width + ix
        else
            x := ix
    }

    if(iy = "center")
    {
        y := % A_ScreenHeight/2 - height/2
    }
    else{
        if(iy < 0)
            y := % A_ScreenHeight - height + iy
        else
            y := iy
    }

}

HideLayoutOSD()
{
    if( !NoDisplayTimeout)
        layoutLayer.Hide()
    SetTimer(HideLayoutOSD,0)
}


HideLayerNameOSD()
{

    if( !NoDisplayTimeout)
        indicatorLayer.Hide()
    SetTimer(HideLayerNameOSD,0)
}


; Reload the app
Reload()
{
	Reload()
}

; Exit the app
Exit(){
	ExitApp()
}

MomentaryLayoutDisplay()
{
    if(!DisplayLayout)
    {
        SetTimer(StopMomentaryDisplay,-%MomentaryLayoutDisplayDuration%)
        DisplayLayout := 1
        MomentaryTimerRunning := 1
    }
}

StopMomentaryDisplay()
{
    SetTimer(StopMomentaryDisplay,0)
    if(MomentaryTimerRunning)
        DisplayLayout := 0
    MomentaryTimerRunning := 0
}
; On tray menu action, change check mark and write .ini file
ChangeDisplayLayout()
{

    if(DisplayLayout)
    {
        DisplayLayout := 0
        Tray.UnCheck("Show Layout")
    }
    Else{
        DisplayLayout := 1
        Tray.Check("Show Layout")
    }
	IniWrite(DisplayLayout, script_ini, "Layout", "DisplayLayout")
}


; On tray menu action, change check mark and write .ini file
ChangeDisplayLayerName()
{
    if(DisplayLayerName)
    {
        DisplayLayerName := 0
        Tray.UnCheck("Show Layer Name")
    }
    Else{
        DisplayLayerName := 1
        Tray.Check("Show Layer Name")
    }
	IniWrite(DisplayLayerName, script_ini, "LayerName", "DisplayLayerName")
}

; On tray menu action, change check mark and write .ini file
ChangeNoDisplayTimeout(){
    if(NoDisplayTimeout)
    {
        NoDisplayTimeout := 0
        indicatorLayer := Gui()
        indicatorLayer.Hide()
        layoutLayer := Gui()
        layoutLayer.Hide()
        Tray:= A_TrayMenu
        Tray.UnCheck("No timeout")
    }
    Else{
        NoDisplayTimeout := 1
        Tray.Check("No timeout")
    }
	IniWrite(NoDisplayTimeout, script_ini, "General", "NoDisplayTimeout")
}
