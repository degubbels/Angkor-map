/*
    Find three trackballs and launch requisit Input Manager processes

    @degu
*/
#SingleInstance, force
#Include %A_ScriptDir%\Lib\BIGA\export.ahk
SetFormat, FloatFast, 3.0

global SHOW_UI := False
global SHOW_UPDATES := False

; Initial device numbers
global DEFAULT_NAMES := ["e35","244", "20d"]
global currentHandles := [0, 0, 0]
global currentNames := ["", "", ""]
global currentPIDs := [0, 0, 0]

; Create hidden GUI to get a handle for windows
Gui, +Resize -MaximizeBox -MinimizeBox +LastFound
Gui, Add, Text, , Trackball Manager
if (SHOW_UI) {
    if (SHOW_UPDATES) {
        Gui, Add, ListView, r10 w800 vTrackballList, # | Handle      | Name | Last Timestamp | pid
    } else {
        Gui, Add, ListView, r3 w800 vTrackballList, # | Handle      | Name
    }
}
GuiHandle := WinExist()

if (SHOW_UI) {
    Gui, Show

    ; populate UI
    LV_Add(1,1,0,"_")
    LV_Add(2,2,0,"_")
    LV_Add(3,3,0,"_")
}

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

global devices
AHKHID_GetRegisteredDevs(devices)
For i, v in devices {
    MsgBox %v%
}
return

GuiClose:

For i, v in currentPIDs {
    Process, close, %v%
}

ExitApp


InputMsg(wParam, lParam) {
    local handle, isTrackball

    ; Get device info
    handle := AHKHID_GetInputInfo(lParam, II_DEVHANDLE)

    ; Don't process active devices
    local sameHandle := A.indexOf(currentHandles, handle)
    if (sameHandle != -1) {
        if (SHOW_UPDATES) {
            LV_Modify(sameHandle, "Col4", A_TickCount)
        }
        return
    }

    ; Check if device is a trackball
    local devname := AHKHID_GetDevName(handle, True)
    local devnameparts := StrSplit(devname, "#")
    If (devnameparts[2] == "VID_D209&PID_15A1") {
        isTrackball := True
    } else {
        ; Only process trackballs
        return
    }
    local name := SubStr(devnameparts[3], 3, 3)

    ; Unused default devices get preference
    local defaultIndex := A.indexOf(DEFAULT_NAMES, name)
    if (defaultIndex != -1) {
        
        launchManager(defaultIndex, handle, name)
    } else {
        local unlaunchedId := A.indexOf(currentHandles, 0)
        if (unlaunchedId != -1) {
            launchManager(unlaunchedId, handle, name)
        } else {
            local sameNameId := A.indexOf(currentNames, name)
            if (sameNameId != -1) {
                ; Replace device of same name
                launchManager(sameNameId, handle, name)
            } else {
                ; We don't know which device was replaced, reset all
                reset()
            }
        }
    }

}

launchManager(id, handle, name) {
    local pid, oldPID

    oldPID := currentPIDs[id]
    if (oldPID != 0) {
        Process, Close, %oldPID%
    }
    
    currentHandles[id] := handle
    currentNames[id] := name

    run InputManager.exe %id% %name%,,,pid
    currentPIDs[id] := pid

    if (SHOW_UI) {
        LV_Modify(id,,id, handle, name, A_TickCount, pid)
    }
}

reset() {
    global currentHandles := [0, 0, 0]
    global currentNames := ["", "", ""]

    if (SHOW_UI) {
        LV_Modify(1,,1,0,"_")
        LV_Modify(2,,2,0,"_")
        LV_Modify(3,,3,0,"_")
    }
}