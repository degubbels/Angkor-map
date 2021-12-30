/*

    AHKHID Remapper

    @degu
*/
#SingleInstance
#Include %A_ScriptDir%\Lib\BIGA\export.ahk

;To make x,y movements look nice
SetFormat, FloatFast, 3.0

; Create GUI
Gui, +Resize -MaximizeBox -MinimizeBox +LastFound
; Create List view for input events with width=600px, 10rows
Gui, Add, ListView, r5 w600 vDeviceInputList, # | Handle     | isTrackball | X | Y | UNIX timestamp (ms) | Device Name
GuiHandle := WinExist()
Gui, Show

; Load BIGA Lib
A := new biga()

Global InputDevices := []

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
    local h, i, x, y, t, devname, devnameparts, isTrackball
    Critical

    ; Get device info
    h := AHKHID_GetInputInfo(lParam, II_DEVHANDLE)
    devname := AHKHID_GetDevName(h, True)
    x := AHKHID_GetInputInfo(lParam, II_ II_MSE_LASTX)
    y := AHKHID_GetInputInfo(lParam, II_ II_MSE_LASTY)

    ; Check if device is a trackball
    devnameparts := StrSplit(devname, "#")
    If (devnameparts[2] == "VID_D209&PID_15A1") {
        isTrackball := True
    } else {
        isTrackball := False
    }

    If (isTrackball) {
        
        i := A.indexOf(InputDevices, h)
        
        If (i == -1) {
            ; Register new device
            InputDevices.push(h)
            LV_Add("", i, h, isTrackball, x, y, A_TickCount, devname)
        } Else {
            
            LV_Modify(i,, i, h, isTrackball, x, y, A_TickCount, devname)
        }

        sendTrackballInput(h, i, x, y)
    }
}

sendTrackballInput(h, i, x, y) {

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
    Send {U+0A%i%%x%%y%}
}

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