#Requires AutoHotkey v2.1-alpha.16
#SingleInstance Force

#Include AHKHID.ahk

KBLayerHelper()

class KBLayerHelper {
    ; Static properties
    static Version := "17/01/2023"
    static Author := "Raph.Coder"
    static Title := "KBLayerHelper"
    
    __New() {
        this.InitializeProperties()
        this.ReadIniFile()
        this.SetupTrayMenu()
        this.SetupHotkeys()
        this.SetupGUI()
        
        SetWorkingDir(A_ScriptDir)
        this.SetTrayIcon(this.LayerArray[0].ico)
    }
    
    InitializeProperties() {
        ; Use KBLayerHelper.Title to access the static property
        this.ScriptIni := A_ScriptDir "\" KBLayerHelper.Title ".ini"
        this.MomentaryTimerRunning := 0
        this.LayerArray := [{}]
        
        ; Setup main GUI and register for input
        this.MainGui := Gui()
        this.GuiHandle := WinExist()
        
        ; Setup layer display GUIs
        this.IndicatorLayer := Gui()
        this.LayoutLayer := Gui()
        
        ; Setup message handler
        AHKHID_UseConstants()
        this.UsagePage := 65329
        this.Usage := 116
        OnMessage(0x00FF, this.InputMsg.Bind(this))
        AHKHID_Register(this.UsagePage, this.Usage, this.GuiHandle, RIDEV_INPUTSINK)
    }
    
    ReadIniFile() {
        ; Device settings
        this.VendorId := IniRead(this.ScriptIni, "Device", "VendorId", 16715)
        this.ProductId := IniRead(this.ScriptIni, "Device", "ProductId", 1)
        
        ; General settings
        this.NoDisplayTimeout := IniRead(this.ScriptIni, "General", "NoDisplayTimeout", 0)
        this.LockHotKey := IniRead(this.ScriptIni, "General", "LockHotKey", "!NumLock")
        this.LayoutDisplayHotKey := IniRead(this.ScriptIni, "General", "LayoutDisplayHotKey", "+^!#d")
        this.MomentaryLayoutDisplayHotKey := IniRead(this.ScriptIni, "General", "MomentaryLayoutDisplayHotKey", "+^!#f")
        this.MomentaryLayoutDisplayDuration := IniRead(this.ScriptIni, "General", "MomentaryLayoutDisplayDuration", 1000)
        
        ; Layout settings
        this.DisplayLayout := IniRead(this.ScriptIni, "Layout", "DisplayLayout", 1)
        inipos := IniRead(this.ScriptIni, "Layout", "Position", "center,-50")
        this.LayoutPosition := StrSplit(inipos, ",", " `t")
        inisize := IniRead(this.ScriptIni, "Layout", "Size", "300,200")
        this.LayoutSize := StrSplit(inisize, ",", " `t")
        this.LayoutFontSize := IniRead(this.ScriptIni, "Layout", "FontSize", 20)
        this.LayoutTransparency := IniRead(this.ScriptIni, "Layout", "Transparency", 128)
        this.LayoutDuration := IniRead(this.ScriptIni, "Layout", "Duration", 1000)
        
        ; Layer name settings
        this.DisplayLayerName := IniRead(this.ScriptIni, "LayerName", "DisplayLayerName", 1)
        inipos := IniRead(this.ScriptIni, "LayerName", "Position", "center,-50")
        this.LayerNamePosition := StrSplit(inipos, ",", " `t")
        inisize := IniRead(this.ScriptIni, "LayerName", "Size", "200,50")
        this.LayerNameSize := StrSplit(inisize, ",", " `t")
        this.LayerNameFontSize := IniRead(this.ScriptIni, "LayerName", "FontSize", 20)
        this.LayerNameDuration := IniRead(this.ScriptIni, "LayerName", "Duration", 1000)
        this.LayerNameTransparency := IniRead(this.ScriptIni, "LayerName", "Transparency", 128)
        
        this.ReadLayerSections()
    }
    
    ReadLayerSections() {
        outputVarSection := IniRead(this.ScriptIni, "Layers")
        
        for array_idx, layerLine in StrSplit(outputVarSection, "`n", " `t") {
            idx := array_idx - 1
            pos := InStr(layerLine, "=")
            
            if (pos > 0) {
                layerLine := SubStr(layerLine, pos + 1)
                curLayerArray := StrSplit(layerLine, ",", " `t")
                
                layerRef := Trim(curLayerArray[1]) ? Trim(curLayerArray[1]) : Format("{:01}", idx)
                
                this.LayerArray[layerRef] := {
                    label: Trim(curLayerArray[2]) ? Trim(curLayerArray[2]) : "Layer " layerRef,
                    ico: Trim(curLayerArray[3]) ? Trim(curLayerArray[3]) : "./icons/ico/Number-" layerRef ".ico",
                    image: Trim(curLayerArray[4]) ? Trim(curLayerArray[4]) : "./png/Layer-" layerRef ".png"
                }
            }
        }
    }
    
    SetupTrayMenu() {
        A_TrayMenu.Delete()
        A_TrayMenu.Add("Show Layout", this.ChangeDisplayLayout.Bind(this))
        A_TrayMenu.Add("Show Layer Name", this.ChangeDisplayLayerName.Bind(this))
        A_TrayMenu.Add("No timeout", this.ChangeNoDisplayTimeout.Bind(this))
        A_TrayMenu.Add()
        A_TrayMenu.Add("Reload " KBLayerHelper.Title, (*) => Reload())
        A_TrayMenu.Add("Exit " KBLayerHelper.Title, (*) => ExitApp())
         
        if this.DisplayLayout
            A_TrayMenu.Check("Show Layout")
        if this.DisplayLayerName
            A_TrayMenu.Check("Show Layer Name")
        if this.NoDisplayTimeout
            A_TrayMenu.Check("No timeout")
    }
    
    SetupHotkeys() {
        HotKey(this.LockHotKey, this.ChangeNoDisplayTimeout.Bind(this))
        HotKey(this.LayoutDisplayHotKey, this.ChangeDisplayLayout.Bind(this))
        HotKey(this.MomentaryLayoutDisplayHotKey, this.MomentaryLayoutDisplay.Bind(this))
    }
    
    SetupGUI() {
        this.MainGui.Show()
    }
    
    InputMsg(wParam, lParam, msg, hwnd) {
        Critical()
        
        r := AHKHID_GetInputInfo(lParam, II_DEVTYPE)
        
        if (r = RIM_TYPEHID) {
            h := AHKHID_GetInputInfo(lParam, II_DEVHANDLE)
            r := AHKHID_GetInputData(lParam, &uData)
            offset := 0x1
            
            iVendorID := AHKHID_GetDevInfo(h, DI_HID_VENDORID, true)
            iProductID := AHKHID_GetDevInfo(h, DI_HID_PRODUCTID, true)
            
            if (iVendorID = this.VendorId) {
                mystring := Trim(StrGet(&uData + offset, "UTF-8"), OmitChars := "`t`n`r")
                
                loop parse mystring, "`n", "`r" {
                    foundPos := InStr(A_LoopField, "KBHLayer")
                    if (foundPos > 0) {
                        idx := SubStr(A_LoopField, foundPos + 8)
                        this.SetTrayIcon(this.LayerArray[idx].ico)
                        
                        if this.DisplayLayout
                            this.ShowLayoutOSD(this.LayerArray[idx].label, this.LayerArray[idx].image)
                        if this.DisplayLayerName
                            this.ShowLayerNameOSD(this.LayerArray[idx].label)
                    }
                }
            }
        }
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
    
    ShowLayerNameOSD(key) {
        width := this.LayerNameSize[1]
        height := this.LayerNameSize[2]
        
        this.ComputePosition(this.LayerNamePosition[1], this.LayerNamePosition[2], 
            width, height, &xPlacement, &yPlacement)
            
        if !WinExist("ahk_id " this.IndicatorLayer.Hwnd) {
            this.IndicatorLayer.BackColor := "FF0000"
            this.IndicatorLayer.MarginX := 0
            this.IndicatorLayer.MarginY := 0
            
            this.IndicatorLayer.SetFont("s" this.LayerNameFontSize " cWhite", "Verdana")
            this.LayerNameText := this.IndicatorLayer.Add("Text", 
                "x0 y0 w" width " h" height " BackGroundTrans Center", key)
        } else {
            this.LayerNameText.Text := key
        }
        
        this.IndicatorLayer.Show("x" xPlacement " y" yPlacement " NoActivate AutoSize")
        WinSetExStyle(32, "ahk_id " this.IndicatorLayer.Hwnd)
        WinSetTransparent(this.LayerNameTransparency, "ahk_id " this.IndicatorLayer.Hwnd)
        
        SetTimer(this.HideLayerNameOSD.Bind(this), -this.LayerNameDuration)
    }
    
    ShowLayoutOSD(key, image) {
        width := this.LayoutSize[1]
        height := this.LayoutSize[2]
        
        if !WinExist("ahk_id " this.LayoutLayer.Hwnd) {
            this.LayoutLayer.MarginX := 0
            this.LayoutLayer.MarginY := 0
            
            if FileExist(image) {
                this.LayoutPicture := this.LayoutLayer.Add("Picture", 
                    "AltSubmit BackgroundTrans", image)
                    
                ControlGetPos(,, &iWidth, &iHeight,, "ahk_id " this.LayoutPicture.Hwnd)
                
                oWidth := width
                oHeight := height
                
                if (iWidth / iHeight > width/height)
                    oHeight := width*iHeight/iWidth
                else
                    oWidth := height*iWidth/iHeight
                    
                this.LayoutPicture.Move(width/2-oWidth/2, height-oHeight, oWidth, oHeight)
            }
            
            this.LayoutLayer.SetFont("s" this.LayoutFontSize " cBlack", "Verdana")
            this.LayoutText := this.LayoutLayer.Add("Text", 
                "y0 x0 w" width " h" height " BackGroundTrans Center", key)
        } else {
            this.LayoutText.Text := key
            if FileExist(image)
                this.LayoutPicture.Value := image
        }
        
        this.ComputePosition(this.LayoutPosition[1], this.LayoutPosition[2], 
            width, height, &xPlacement, &yPlacement)
            
        if FileExist(image) {
            this.LayoutLayer.Show("x" xPlacement " y" yPlacement " NoActivate AutoSize")
            WinSetExStyle(32, "ahk_id " this.LayoutLayer.Hwnd)
            WinSetTransparent(this.LayoutTransparency, "ahk_id " this.LayoutLayer.Hwnd)
            
            SetTimer(this.HideLayoutOSD.Bind(this), -this.LayoutDuration)
            if this.MomentaryTimerRunning
                SetTimer(this.StopMomentaryDisplay.Bind(this), -this.MomentaryLayoutDisplayDuration)
        } else {
            this.HideLayoutOSD()
        }
    }
    
    HideLayoutOSD(*) {
        if !this.NoDisplayTimeout
            this.LayoutLayer.Hide()
    }
    
    HideLayerNameOSD(*) {
        if !this.NoDisplayTimeout
            this.IndicatorLayer.Hide()
    }
    
    SetTrayIcon(iconname) {
        if FileExist(iconname)
            TraySetIcon(iconname)
    }
    
    MomentaryLayoutDisplay(*) {
        if !this.DisplayLayout {
            SetTimer(this.StopMomentaryDisplay.Bind(this), -this.MomentaryLayoutDisplayDuration)
            this.DisplayLayout := 1
            this.MomentaryTimerRunning := 1
        }
    }
    
    StopMomentaryDisplay(*) {
        if this.MomentaryTimerRunning
            this.DisplayLayout := 0
        this.MomentaryTimerRunning := 0
    }
    
    ChangeDisplayLayout(*) {
        this.DisplayLayout := !this.DisplayLayout
        if this.DisplayLayout
            A_TrayMenu.Check("Show Layout")
        else
            A_TrayMenu.UnCheck("Show Layout")
        IniWrite(this.DisplayLayout, this.ScriptIni, "Layout", "DisplayLayout")
    }
    
    ChangeDisplayLayerName(*) {
        this.DisplayLayerName := !this.DisplayLayerName
        if this.DisplayLayerName
            A_TrayMenu.Check("Show Layer Name")
        else
            A_TrayMenu.UnCheck("Show Layer Name")
        IniWrite(this.DisplayLayerName, this.ScriptIni, "LayerName", "DisplayLayerName")
    }
    
    ChangeNoDisplayTimeout(*) {
        this.NoDisplayTimeout := !this.NoDisplayTimeout
        if this.NoDisplayTimeout {
            A_TrayMenu.Check("No timeout")
        } else {
            A_TrayMenu.UnCheck("No timeout")
            this.IndicatorLayer.Hide()
            this.LayoutLayer.Hide()
        }
        IniWrite(this.NoDisplayTimeout, this.ScriptIni, "General", "NoDisplayTimeout")
    }
}