/*

    AHKHID Remapper

    @degu
*/
#SingleInstance
#Include %A_ScriptDir%\Lib\BIGA\export.ahk

; Create GUI
Gui, New
; Create List view for input events with width=600px, 10rows
Gui, Add, ListView, r5 w600 vDeviceInputList, Handle | X | Y | Device Name
Gui, Show

; Load BIGA Lib
A := new biga()

Global InputDevices := []

; Load AHKHID lib constants
AHKHID_UseConstants()

;Intercept WM_INPUT
OnMessage(0x00FF, "InputMsg")

AHKHID_AddRegister(1)
; UsagePage 1 Usage 2 for mouse (no flags set)
AHKHID_AddRegister(1, 2, 0)

AHKHID_Register()
return

GuiClose:
ExitApp


InputMsg(wParam, lParam) {
    local h, i, x, y, devinfo
    Critical

    h := AHKHID_GetInputInfo(lParam, II_DEVHANDLE)
    x := AHKHID_GetInputInfo(lParam, II_ II_MSE_LASTX)
    y := AHKHID_GetInputInfo(lParam, II_ II_MSE_LASTY)
    devinfo := AHKHID_GetDevName(h, True)

    i := A.indexOf(InputDevices, h)
    
    If (i == -1) {
        ; Register new device
        InputDevices.push(h)
        LV_Add("", h, x, y, devinfo)
    } Else {
        
        LV_Modify(i,, h, x, y, devinfo)
    }
}