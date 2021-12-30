/*

    AHKHID Remapper

    @degu
*/
#SingleInstance, off
#Include %A_ScriptDir%\Lib\BIGA\export.ahk

;To make x,y movements look nice
SetFormat, FloatFast, 3.0

; Device numbers to seperate the trackballs
global DEV1 := "6&20d96b6f&0&0000"
global DEV2 := "6&24472387&0&0000"
global DEV3 := "6&e35d201&0&0000"

; Device number for the specified device
global devnumber := ""

; ID (1/2/3) for the specified device, equals the CLI argument
global devid := 0
If (A_Args.Length() > 0) {
    devid := A_Args[1]
    If A_Args[1] == "1" {
        devnumber := DEV1
    }
    If A_Args[1] == "2" {
        devnumber := DEV2
    }
    If A_Args[1] == "3" {
        devnumber := DEV3
    }
} else {
    MsgBox, please enter desired device (1/2/3)
    ExitApp
}

; Device handle for the specified trackball to follow
global devhandle := 0

global skippedCount := 0

; Create hidden GUI to get a handle for windows
Gui, +Resize -MaximizeBox -MinimizeBox +LastFound
Gui, Add, Text, , Trackball %devid%
GuiHandle := WinExist()


; Load AHKHID lib constants
AHKHID_UseConstants()

;Intercept WM_INPUT
OnMessage(0x00FF, "InputMsg")

; Register script to receive input messages from mouse-type HID devices
AHKHID_AddRegister(1)
; UsagePage 1 Usage 2 for mouse. Inputsink when specified a gui handle allows the manager to capture background input
AHKHID_AddRegister(1, 2, GuiHandle, RIDEV_INPUTSINK)
AHKHID_Register()

return

; Exit script if gui is closed
GuiClose:
ExitApp


; Process incoming HID input message
InputMsg(wParam, lParam) {
    local h
    Critical

    ; Get device info
    h := AHKHID_GetInputInfo(lParam, II_DEVHANDLE)

    ; Find specified device
    if (devhandle == 0) {
        tryRegisterDevHandle(h)
    } else {
        if (h == devhandle) {

            if (skippedCount > 2) {
                skippedCount := 0
                sendTrackballInput(h, lParam)
            } else {
                skippedCount +=1
            }
        }
    }
}

; Get input from this device and send to app
sendTrackballInput(h, lParam) {
    local x, y

    x := AHKHID_GetInputInfo(lParam, II_ II_MSE_LASTX)
    y := AHKHID_GetInputInfo(lParam, II_ II_MSE_LASTY)

    ; Wrap negative around 16
    if (x < 0) {
        x := 15 + x 
    }
    if (y < 0) {
        y := 15 + y
    }

    ; Convert to hex chars
    x := charToHex(x)
    y := charToHex(y)

    ; Send data to browser by unicoded-code message sent as keypresses
    ; A message consists of 4 hex chars
    ; 0: Constant A signalling that this char is an input message
    ; 1: The device ID
    ; 2: Input on x-axis (negative numbers wrapped around)
    ; 3: Input on y-axis (negative numbers wrapped around)
    Send {U+0A%devid%%x%%y%}
}

; Check if this device is the desired trackpad, if so, register the handle
tryRegisterDevHandle(h) {
    devname := AHKHID_GetDevName(h, True)

    ; Check if device is a trackball
    devnameparts := StrSplit(devname, "#")

    ; Check that the device is a trackball
    If (devnameparts[2] == "VID_D209&PID_15A1") {
        
        ; Check that the device is the desired device
        If (devnameparts[3] == devnumber) {
            devhandle := h
        }
    }
}

; Get hex representation for a single char
charToHex(dec) {
    if (dec == 15) {
        return "F"
    } else if (dec == 14) {
        return "E"
    } else if (dec == 13) {
        return "D"
    } else if (dec == 12) {
        return "C"
    } else if (dec == 11) {
        return "B"
    } else if (dec == 10) {
        return "A"
    } else {
        return dec
    }
}