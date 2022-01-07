/*
    Find three trackballs and launch requisit Input Manager processes

    @degu
*/
#SingleInstance, force
#Include %A_ScriptDir%\Lib\BIGA\export.ahk
SetFormat, FloatFast, 3.0

; Initial device numbers
global DEFAULT_NAMES := ["6&2593412b&0&0000", "6&228ff76&0&0000", "6&e35d201&0&0000"]
global launched := [False, False, False]
global currentHandles := [0, 0, 0]
global currentNames := ["", "", ""]



; Create hidden GUI to get a handle for windows
Gui, +Resize -MaximizeBox -MinimizeBox +LastFound
Gui, Add, Text, , Trackball %devid%
GuiHandle := WinExist()

; Load BIGA Lib
A := new biga()

; Load AHKHID lib constants
AHKHID_UseConstants()

;Intercept WM_INPUT
OnMessage(0x00FF, "InputMsg")

; Register script to receive input messages from mouse-type HID devices
AHKHID_AddRegister(1)
; UsagePage 1 Usage 2 for mouse. Inputsink when specified a gui handle allows the manager to capture background input
AHKHID_AddRegister(1, 2, GuiHandle, RIDEV_INPUTSINK)
AHKHID_Register()

InputMsg(wParam, lParam) {
    local handle, name, nameparts, isTrackball, rept

    ; Get device info
    handle := AHKHID_GetInputInfo(lParam, II_DEVHANDLE)

    ; Don't process active devices
    rept := A.indexOf(currentHandles, handle)
    if (rept != -1) {
        return
    }

    ; Check if device is a trackball
    name := AHKHID_GetDevName(handle, True)
    nameparts := StrSplit(name, "#")
    If (nameparts[2] == "VID_D209&PID_15A1") {
        isTrackball := True
    } else {
        isTrackball := False
    }

    ; Only process trackballs
    if (!isTrackball) {
        return
    }

    ; Unused default devices get preference
    local defaultIndex := A.indexOf(DEFAULT_NAMES, nameparts[3])
    if (defaultIndex != -1) {
        
        launchManager(defaultIndex, handle, nameparts[3])
    } else {
        local unlaunchedId := A.indexOf(currentHandles, 0)
        if (unlaunchedId != -1) {
            launchManager(unlaunchedId, handle, nameparts[3])
        }
    }

}

launchManager(id, handle, name) {
    
    currentHandles[id] := handle
    currentNames[id] := name

    MsgBox, register device %name% as %id%
}