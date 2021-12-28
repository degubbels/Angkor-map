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
Gui, Add, ListView, r5 w600 vDeviceInputList, # | Handle | X | Y | Device Name
GuiHandle := WinExist()
Gui, Show

; Load BIGA Lib
A := new biga()

Global InputDevices := []

; Load AHKHID lib constants
AHKHID_UseConstants()

;Intercept WM_INPUT
OnMessage(0x00FF, "InputMsg")

AHKHID_AddRegister(1)
; UsagePage 1 Usage 2 for mouse. Inputsink when specified a gui handle allows the manager to capture background input
AHKHID_AddRegister(1, 2, GuiHandle, RIDEV_INPUTSINK)

AHKHID_Register()


wdriver := ComObjCreate("Selenium.ChromeDriver")
wdriver.SetCapability("goog:chromeOptions", "{""excludeSwitches"":[""enable-automation""]}")
wdriver.Start("chrome", "http://localhost:3000")
wdriver.Get("http://localhost:3000")

return


GuiClose:
; wd.delete()
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
        LV_Add("", i, h, x, y, devinfo)
    } Else {
        
        LV_Modify(i,, i, h, x, y, devinfo)
    }

    ; Send data to browser by executing js snippets
    if (i == 2) {
        wdriver.ExecuteScript("document.getElementById('A').getElementsByClassName('posreceive-x')[0].value = " + x)
        wdriver.ExecuteScript("document.getElementById('A').getElementsByClassName('posreceive-y')[0].value = " + y)
    }

    if (i == 1) {
        ; wd.execute("alert('wd hid input')")
    }
}