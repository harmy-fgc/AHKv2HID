/*! TheGood
    AHKHID - An AHK implementation of the HID functions.
    Last updated: June 14th, 2010

USING THE CONSTANTS:

If you explicitly #include AHKHID in your script, you will have all the constants available to you. Otherwise, if AHKHID is
in your library folder and you do not wish to explicitly #include it, you can call AHKHID_UseConstants() to have the
constants available to you.

FUNCTION LIST:
_____________________
AHKHID_UseConstants()

See the section above titled "USING THE CONSTANTS"
___________________________________
AHKHID_Initialize(bRefresh = False)

You don't have to call this function manually. It is automatically called by other functions to get the pointer of the
RAWINPUTDEVICELIST struct array. However, if a new device is plugged in, you will have to refresh the listing by calling it
with bRefresh = True. Returns -1 on error (with error message in ErrorLevel).
____________________
AHKHID_GetDevCount()

Returs the number of HID devices connected to this computer.
Returns -1 on error (with error message in ErrorLevel).
______________________
AHKHID_GetDevHandle(i)

Returns the handle of device i (starts at 1).
Mostly used internally for API calls.
__________________________
AHKHID_GetDevIndex(Handle)

Returns the index (starts at 1) of the device in the enumeration with matching handle.
Returns 0 if not found.
______________________________________
AHKHID_GetDevType(i, IsHandle = False)

Returns the type of the device. See the RIM_ constants for possible values.
If IsHandle is false, then i is considered the index (starts at 1) of the device in the enumeration.
Otherwise it is the handle of the device.
______________________________________
AHKHID_GetDevName(i, IsHandle = False)

Returns the name of the device (or empty string on error, with error message in ErrorLevel).
If IsHandle is false, then i is considered the index (starts at 1) of the device in the enumeration.
Otherwise it is the handle of the device.
____________________________________________
AHKHID_GetDevInfo(i, Flag, IsHandle = False)

Retrieves info from the RID_DEVICE_INFO struct. To retrieve a member, simply use the corresponding flag. A list of flags
can be found at the top of the script (the constants starting with DI_). Each flag corresponds to a member in the struct.
If IsHandle is false, then i is considered the index (starts at 1) of the device in the enumeration. Otherwise it is the
handle of the device. Returns -1 on error (with error message in ErrorLevel).

See Example 1 for an example on how to use it. 
_______________________________________________________________________________
AHKHID_AddRegister(UsagePage = False, Usage = False, Handle = False, Flags = 0)

Allows you to queue up RAWINPUTDEVICE structures before doing the registration. To use it, you first need to initialize the
variable by calling AHKHID_AddRegister(iNumberOfElements). To then add to the stack, simply call it with the parameters you
want (eg. AHKHID_AddRegister(1,6,MyGuiHandle) for keyboards). When you're finally done, you just have to call
AHKHID_Register() with no parameters. The function returns -1 if the struct is full. Redimensioning the struct will erase
all previous structs added. On success, it returns the address of the array of structs (if you'd rather manipulate it
yourself).

See Example 2 for an example on how to use it.

You will need to do this if you want to use advance features of the RAWINPUTDEVICE flags. For example, if you want to
register all devices using Usage Page 1 but would like to exclude devices of Usage Page 1 using Usage 2 (keyboards), then
you need to place two elements in the array. The first one is AHKHID_AddRegister(1,0,MyGuiHandle,RIDEV_PAGEONLY) and the
second one is AHKHID_AddRegister(1,2,MyGuiHandle,RIDEV_EXCLUDE).

Tip: Have a look at all the flags you can use (see the constants starting with RIDEV_). The most useful is RIDEV_INPUTSINK.
Tip: Set Handle to 0 if you want the WM_INPUT messages to go to the window with keyboard focus.
Tip: To unregister, use the flag RIDEV_REMOVE. Note that you also need to use the RIDEV_PAGEONLY flag if the TLC was
registered with it.
____________________________________________________________________________
AHKHID_Register(UsagePage = False, Usage = False, Handle = False, Flags = 0)

This function can be used in two ways. If no parameters are specified, it will use the RAWINPUTDEVICE array created through
AHKHID_AddRegister() and register. Otherwise, it will register only the specified parameters. For example, if you just want
to register the mouse, you can simply do AHKHID_Register(1,2,MyGuiHandle). Returns 0 on success, returns -1 on error (with
error message in ErrorLevel).

See Example 2 for an example on how to use it with the RAWINPUTDEVICE.
See Example 3 for an example on how to use it only with the specified parameters.
____________________________________
AHKHID_GetRegisteredDevs(&ByRef uDev)

This function allows you to get an array of the TLCs that have already been registered.
It fills uDev with an array of RAWINPUTDEVICE and returns the number of elements in the array.
Returns -1 on error (with error message in ErrorLevel).

See Example 2 for an example on how to use it.
______________________________________
AHKHID_GetInputInfo(InputHandle, Flag)

This function is used to retrieve the data upon receiving WM_INPUT messages. By passing the lParam of the WM_INPUT (0xFF00)
messages, it can retrieve all the members of the RAWINPUT structure, except the raw data coming from HID devices (use
AHKHID_GetInputData for that). To retrieve a member, simply specify the flag corresponding to the member you want, and call
the function. A list of all the flags can be found at the top of this script (the constants starting with II_). Returns -1
on error (with error message in ErrorLevel).

See Example 2 for an example on how to use it to retrieve each member of the structure.
See Example 3 for an example on how to interpret members which represent flags.

Tip: You have to use Critical in your message function or you might get invalid handle errors.
Tip: You can check the value of wParam to know if the application was in the foreground upon reception (see RIM_INPUT).
_____________________________________________
AHKHID_GetInputData(InputHandle, &ByRef uData)

This function is used to retrieve the data sent by HID devices of type RIM_TYPEHID (ie. neither keyboard nor mouse) upon
receiving WM_INPUT messages. CAUTION: it does not check if the device is indeed of type HID. It is up to you to do so (you
can use GetInputInfo for that). Specify the lParam of the WM_INPUT (0xFF00) message and the function will put in uData the
raw data received from the device. It will then return the size (number of bytes) of uData. Returns -1 on error (with error
message in ErrorLevel).

See Example 2 for an example on how to use it (although you need an HID device of type RIM_TYPEHID to test it).

*/

AHKHID_Included := True
AHKHID_SetConstants()
;______________________________________
;Flags you can use in AHKHID_GetDevInfo
{
global
DI_DEVTYPE                  := 4

DI_MSE_ID                   := 8
DI_MSE_NUMBEROFBUTTONS      := 12
DI_MSE_SAMPLERATE           := 16

DI_MSE_HASHORIZONTALWHEEL   := 20


DI_KBD_TYPE                 := 8
DI_KBD_SUBTYPE              := 12
DI_KBD_KEYBOARDMODE         := 16
DI_KBD_NUMBEROFFUNCTIONKEYS := 20
DI_KBD_NUMBEROFINDICATORS   := 24
DI_KBD_NUMBEROFKEYSTOTAL    := 28

DI_HID_VENDORID             := 8
DI_HID_PRODUCTID            := 12
DI_HID_VERSIONNUMBER        := 16
DI_HID_USAGEPAGE            := 20 | 0x0100
DI_HID_USAGE                := 22 | 0x0100
;_____________________________________
;Flags you can use in HID_GetInputInfo
II_DEVTYPE          := 0
II_DEVHANDLE        := 8

II_MSE_FLAGS        := 16 | 0x0100

II_MSE_BUTTONFLAGS  := 20 | 0x0100

II_MSE_BUTTONDATA   := 22 | 0x1100

II_MSE_RAWBUTTONS   := 24
II_MSE_LASTX        := 28 | 0x1000

II_MSE_LASTY        := 32 | 0x1000

II_MSE_EXTRAINFO    := 36

II_KBD_MAKECODE     := 16 | 0x0100

II_KBD_FLAGS        := 18 | 0x0100

II_KBD_VKEY         := 22 | 0x0100
II_KBD_MSG          := 24
II_KBD_EXTRAINFO    := 28

II_HID_SIZE         := 16
II_HID_COUNT        := 20

;DO NOT USE WITH AHKHID_GetInputInfo. Use AHKHID_GetInputData instead to retrieve the raw data.
II_HID_DATA         := 24
;__________________________________________________________________________________
;Device type values returned by AHKHID_GetDevType as well as DI_DEVTYPE and II_DEVTYPE
;http://msdn.microsoft.com/en-us/library/ms645568
RIM_TYPEMOUSE       := 0
RIM_TYPEKEYBOARD    := 1
RIM_TYPEHID         := 2
;_______________________________________________________________________________________________
;Different flags for RAWINPUTDEVICE structure (to be used with AHKHID_AddRegister and AHKHID_Register)
;http://msdn.microsoft.com/en-us/library/ms645565
RIDEV_REMOVE        := 0x00000001

RIDEV_EXCLUDE       := 0x00000010


RIDEV_PAGEONLY      := 0x00000020


RIDEV_NOLEGACY      := 0x00000030

RIDEV_INPUTSINK     := 0x00000100

RIDEV_CAPTUREMOUSE  := 0x00000200
RIDEV_NOHOTKEYS     := 0x00000200



RIDEV_APPKEYS       := 0x00000400


RIDEV_EXINPUTSINK   := 0x00001000



RIDEV_DEVNOTIFY     := 0x00002000

;__________________________________________________
;Different values of wParam in the WM_INPUT message
;http://msdn.microsoft.com/en-us/library/ms645590
RIM_INPUT       := 0

RIM_INPUTSINK   := 1

;__________________________________
;Flags for GetRawInputData API call
;http://msdn.microsoft.com/en-us/library/ms645596
RID_INPUT    := 0x10000003
RID_HEADER   := 0x10000005
;_____________________________________
;Flags for RAWMOUSE (part of RAWINPUT)
;http://msdn.microsoft.com/en-us/library/ms645578

;Flags for the II_MSE_FLAGS member
MOUSE_MOVE_RELATIVE         := 0
MOUSE_MOVE_ABSOLUTE         := 1
MOUSE_VIRTUAL_DESKTOP       := 0x02
MOUSE_ATTRIBUTES_CHANGED    := 0x04

;Flags for the II_MSE_BUTTONFLAGS member
RI_MOUSE_LEFT_BUTTON_DOWN   := 0x0001
RI_MOUSE_LEFT_BUTTON_UP     := 0x0002
RI_MOUSE_RIGHT_BUTTON_DOWN  := 0x0004
RI_MOUSE_RIGHT_BUTTON_UP    := 0x0008
RI_MOUSE_MIDDLE_BUTTON_DOWN := 0x0010
RI_MOUSE_MIDDLE_BUTTON_UP   := 0x0020
RI_MOUSE_BUTTON_4_DOWN      := 0x0040
RI_MOUSE_BUTTON_4_UP        := 0x0080
RI_MOUSE_BUTTON_5_DOWN      := 0x0100
RI_MOUSE_BUTTON_5_UP        := 0x0200
RI_MOUSE_WHEEL              := 0x0400
;____________________________________________
;Flags for the RAWKEYBOARD (part of RAWINPUT)
;http://msdn.microsoft.com/en-us/library/ms645575

;Flag for the II_KBD_MAKECODE member in the event of a keyboard overrun
KEYBOARD_OVERRUN_MAKE_CODE  := 0xFF

;Flags for the II_KBD_FLAGS member
RI_KEY_MAKE             := 0
RI_KEY_BREAK            := 1
RI_KEY_E0               := 2
RI_KEY_E1               := 4
RI_KEY_TERMSRV_SET_LED  := 8
RI_KEY_TERMSRV_SHADOW   := 0x10
;____________________________________
;AHKHID FUNCTIONS
}

AHKHID_Included := true
AHKHID_SetConstants()

AHKHID_UseConstants() {
    global
    AHKHID_Included := false
    AHKHID_SetConstants()
}

   AHKHID_Initialize(bRefresh := false) {
    static uHIDList := Buffer(0, 0), bInitialized := false

    if bInitialized and !bRefresh
        return uHIDList

    iCount := 0
    r := DllCall("GetRawInputDeviceList", "Ptr", 0, "Uint*", iCount, "Uint", 8)

    if (r = -1) or ErrorLevel {
        ErrorLevel := "GetRawInputDeviceList call failed.`nReturn value: " r "`nErrorLevel: " ErrorLevel "`nLine: " A_LineNumber "`nLast Error: " A_LastError
        return -1
    }

    uHIDList := Buffer(iCount * 8, 0)
    r := DllCall("GetRawInputDeviceList", "Ptr", uHIDList, "Uint*", iCount, "Uint", 8)

    if (r = -1) or ErrorLevel {
        ErrorLevel := "GetRawInputDeviceList call failed.`nReturn value: " r "`nErrorLevel: " ErrorLevel "`nLine: " A_LineNumber "`nLast Error: " A_LastError
        return -1
    }

    bInitialized := true
    return uHIDList
}

AHKHID_GetDevCount() {
    iCount := 0
    r := DllCall("GetRawInputDeviceList", "Ptr", 0, "Uint*", &iCount, "Uint", 8)
    
    if (r = -1) or ErrorLevel {
        ErrorLevel := "GetRawInputDeviceList call failed.`nReturn value: " r "`nErrorLevel: " ErrorLevel "`nLine: " A_LineNumber "`nLast Error: " A_LastError
        return -1
    }
    return iCount
}

AHKHID_GetDevHandle(i) {
    return NumGet(AHKHID_Initialize(), (i - 1) * 8, "Ptr")
}

AHKHID_GetDevIndex(Handle) {
    Loop AHKHID_GetDevCount()
        if (NumGet(AHKHID_Initialize(), (A_Index - 1) * 8, "Ptr") = Handle)
            return A_Index
    return 0
}

AHKHID_GetDevType(i, IsHandle := false) {
    return !IsHandle ? NumGet(AHKHID_Initialize(), ((i - 1) * 8) + 4, "Uint")
        : NumGet(AHKHID_Initialize(), ((AHKHID_GetDevIndex(i) - 1) * 8) + 4, "Uint")
}

AHKHID_GetDevName(i, IsHandle := false) {
    h := IsHandle ? i : AHKHID_GetDevHandle(i)
    iLength := 0
    
    r := DllCall("GetRawInputDeviceInfo", "Ptr", h, "Uint", 0x20000007, "Ptr", 0, "Uint*", &iLength)
    if (r = -1) or ErrorLevel {
        ErrorLevel := "GetRawInputDeviceInfo call failed.`nReturn value: " r "`nErrorLevel: " ErrorLevel "`nLine: " A_LineNumber "`nLast Error: " A_LastError
        return ""
    }
    
    buf := Buffer(iLength + 1, 0)
    r := DllCall("GetRawInputDeviceInfo", "Ptr", h, "Uint", 0x20000007, "Ptr", buf, "Uint*", &iLength)
    if (r = -1) or ErrorLevel {
        ErrorLevel := "GetRawInputDeviceInfo call failed.`nReturn value: " r "`nErrorLevel: " ErrorLevel "`nLine: " A_LineNumber "`nLast Error: " A_LastError
        return ""
    }
    
    return StrGet(buf)
}

AHKHID_GetDevInfo(i, Flag, IsHandle := false) {
    static uInfo := '', iLastHandle := 0
    
    h := IsHandle ? i : AHKHID_GetDevHandle(i)
    
    if (h = iLastHandle)
        return NumGet(uInfo, Flag, AHKHID_NumIsShort(Flag) ? "UShort" : "Uint")
    
    iLength := 0
    r := DllCall("GetRawInputDeviceInfo", "Ptr", h, "Uint", 0x2000000b, "Ptr", 0, "Uint*", &iLength)
    if (r = -1) or ErrorLevel {
        ErrorLevel := "GetRawInputDeviceInfo call failed.`nReturn value: " r "`nErrorLevel: " ErrorLevel "`nLine: " A_LineNumber "`nLast Error: " A_LastError
        return -1
    }
    
    uInfo := Buffer(iLength, 0)
    NumPut("Ptr", iLength, uInfo)
    
    r := DllCall("GetRawInputDeviceInfo", "Ptr", h, "Uint", 0x2000000b, "Ptr", &uInfo, "Uint*", &iLength)
    if (r = -1) or ErrorLevel {
        ErrorLevel := "GetRawInputDeviceInfo call failed.`nReturn value: " r "`nErrorLevel: " ErrorLevel "`nLine: " A_LineNumber "`nLast Error: " A_LastError
        return -1
    }
    
    iLastHandle := h
    return NumGet(uInfo, Flag, AHKHID_NumIsShort(Flag) ? "UShort" : "Uint")
}

AHKHID_AddRegister(UsagePage := False, Usage := False, Handle := False, Flags := 0) {
    static uDev, iIndex := 0, iCount := 0

    ; If no parameters are provided, return the pointer to uDev
    if !UsagePage && !Usage && !Handle && !Flags
        return uDev

    ; If UsagePage is "Count", return the current count
    if (UsagePage = "Count")
        return iCount

    ; Initialize the buffer if UsagePage is provided
    if UsagePage && !Usage && !Handle && !Flags {
        iCount := UsagePage
        iIndex := 0
        uDev := Buffer(iCount * 12, 0)  ; Allocate memory for multiple RAWINPUTDEVICE structures
        return uDev
    }

    ; If the index exceeds the count, return -1
    if (iIndex = iCount)
        return -1

    ; Ensure Handle is valid
    Handle := ((Flags & 0x00000001) Or (Flags & 0x00000010)) ? 0 : Handle

    ; Use NumPut to store values in the buffer
    NumPut("UShort", UsagePage, uDev, (iIndex * 12) + 0)
    NumPut("UShort", Usage, uDev, (iIndex * 12) + 2)
    NumPut("UInt", Flags, uDev, (iIndex * 12) + 4)
    NumPut("UPtr", Handle, uDev, (iIndex * 12) + 8)

    ; Increment the index
    iIndex += 1
    return uDev
}

   AHKHID_Register(UsagePage := False, Usage := False, Handle := False, Flags := 0) {
    ; Case 1: No parameters provided, use the RAWINPUTDEVICE array created by AHKHID_AddRegister
    if !UsagePage && !Usage && !Handle && !Flags {
        r := DllCall("RegisterRawInputDevices", "Ptr", AHKHID_AddRegister(), "UInt", AHKHID_AddRegister("Count"), "UInt", 12)
        if !r {
            ErrorLevel := "RegisterRawInputDevices call failed.`nReturn value: " r "`nErrorLevel: " ErrorLevel "`nLine: " A_LineNumber "`nLast Error: " A_LastError
            return -1
        }
    } else {
        ; Case 2: Parameters provided, register a single RAWINPUTDEVICE structure
        ; Initialize uDev as a buffer with 12 bytes for the RAWINPUTDEVICE structure
        uDev := Buffer(12, 0)

        ; Ensure Handle is valid; set to 0 if invalid
        if !IsNumber(Handle) || Handle = ""
            Handle := 0


        ; Use NumPut to store values in the buffer
        try {
            NumPut("UShort", UsagePage, uDev, 0)  ; UsagePage at offset 0
            NumPut("UShort", Usage, uDev, 2)      ; Usage at offset 2
            NumPut("UInt", Flags, uDev, 4)        ; Flags at offset 4
            NumPut("UPtr", Handle, uDev, 8)       ; Handle at offset 8
        }

        ; Call RegisterRawInputDevices with the buffer
        r := DllCall("RegisterRawInputDevices", "Ptr", uDev, "UInt", 1, "UInt", 12)
    }

    return 0
}

   AHKHID_GetRegisteredDevs(&uDev) {
       iCount := Buffer(4, 0)
       r := DllCall("GetRegisteredRawInputDevices", "Ptr", 0, "Uint*", iCount, "Uint", 12)
       if ErrorLevel {
           ErrorLevel := "GetRegisteredRawInputDevices call failed.`nReturn value: " r "`nErrorLevel: " ErrorLevel "`nLine: " A_LineNumber "`nLast Error: " A_LastError
           return -1
       }

       if (iCount > 0) {
           uDev := Buffer(iCount * 12, 0)
           r := DllCall("GetRegisteredRawInputDevices", "Ptr", uDev, "Uint*", iCount, "Uint", 12)
           if (r = -1) or ErrorLevel {
               ErrorLevel := "GetRegisteredRawInputDevices call failed.`nReturn value: " r "`nErrorLevel: " ErrorLevel "`nLine: " A_LineNumber "`nLast Error: " A_LastError
               return -1
           }
       }

       return iCount
   }

AHKHID_GetInputInfo(InputHandle, Flag) {
    Static uRawInput := Buffer(0, 0), iLastHandle := 0

    ; Initialize iSize to ensure it has a valid value
    iSize := 0

    if (InputHandle = iLastHandle)
        return NumGet(uRawInput, Flag, AHKHID_NumIsShort(Flag) ? (AHKHID_NumIsSigned(Flag) ? "Short" : "UShort") : (AHKHID_NumIsSigned(Flag) ? "Int" : "UInt"))
    else {
        r := DllCall("GetRawInputData", "Ptr", InputHandle, "Uint", 0x10000003, "Ptr", 0, "Uint*", iSize, "Uint", 16)
        if (r = -1) or ErrorLevel {
            ErrorLevel := "GetRawInputData call failed.`nReturn value: " r "`nErrorLevel: " ErrorLevel "`nLine: " A_LineNumber "`nLast Error: " A_LastError
            return -1
        }

        uRawInput := Buffer(iSize, 0)
        r := DllCall("GetRawInputData", "Ptr", InputHandle, "Uint", 0x10000003, "Ptr", uRawInput, "Uint*", iSize, "Uint", 16)
        if (r = -1) or ErrorLevel {
            ErrorLevel := "GetRawInputData call failed.`nReturn value: " r "`nErrorLevel: " ErrorLevel "`nLine: " A_LineNumber "`nLast Error: " A_LastError
            return -1
        } else if (r != iSize) {
            ErrorLevel := "GetRawInputData did not return the correct size.`nSize returned: " r "`nSize allocated: " iSize
            return -1
        }

        iLastHandle := InputHandle
        return NumGet(uRawInput, Flag, AHKHID_NumIsShort(Flag) ? (AHKHID_NumIsSigned(Flag) ? "Short" : "UShort") : (AHKHID_NumIsSigned(Flag) ? "Int" : "UInt"))
    }
}
AHKHID_GetInputData(InputHandle, &uData) {
    ; Initialize iSize to ensure it has a valid value
    iSize := 0

    r := DllCall("GetRawInputData", "Ptr", InputHandle, "Uint", 0x10000003, "Ptr", 0, "Uint*", iSize, "Uint", 16)
    if (r = -1) or ErrorLevel {
        ErrorLevel := "GetRawInputData call failed.`nReturn value: " r "`nErrorLevel: " ErrorLevel "`nLine: " A_LineNumber "`nLast Error: " A_LastError
        return -1
    }

    uRawInput := Buffer(iSize, 0)
    r := DllCall("GetRawInputData", "Ptr", InputHandle, "Uint", 0x10000003, "Ptr", uRawInput, "Uint*", iSize, "Uint", 16)
    if (r = -1) or ErrorLevel {
        ErrorLevel := "GetRawInputData call failed.`nReturn value: " r "`nErrorLevel: " ErrorLevel "`nLine: " A_LineNumber "`nLast Error: " A_LastError
        return -1
    } else if (r != iSize) {
        ErrorLevel := "GetRawInputData did not return the correct size.`nSize returned: " r "`nSize allocated: " iSize
        return -1
    }

    uData := Buffer(iSize, 0)
    DllCall("RtlMoveMemory", "Ptr", uData, "Ptr", uRawInput + 24, "Uint", iSize)
    return iSize
}

AHKHID_NumIsShort(Flag) {
    local tempFlag := Flag
    if (tempFlag & 0x0100) {
        tempFlag ^= 0x0100
        return true
    }
    return false
}

AHKHID_NumIsSigned(Flag) {
    local tempFlag := Flag
    if (tempFlag & 0x1000) {
        tempFlag ^= 0x1000
        return true
    }
    return false
}