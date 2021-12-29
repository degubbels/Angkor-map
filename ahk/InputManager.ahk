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
Gui, Add, ListView, r5 w600 vDeviceInputList, # | Handle | X | Y | UNIX timestamp (ms)        | Device Name
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


; wdriver := ComObjCreate("Selenium.ChromeDriver")
; wdriver.SetCapability("goog:chromeOptions", "{""excludeSwitches"":[""enable-automation""]}")
; wdriver.Start("chrome", "http://localhost:3000")
; wdriver.Get("http://localhost:3000")

return


GuiClose:
; wd.delete()
ExitApp

toHex(dec) {
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


InputMsg(wParam, lParam) {
    local h, i, x, y, t, devinfo
    Critical

    h := AHKHID_GetInputInfo(lParam, II_DEVHANDLE)
    x := AHKHID_GetInputInfo(lParam, II_ II_MSE_LASTX)
    y := AHKHID_GetInputInfo(lParam, II_ II_MSE_LASTY)
    devinfo := AHKHID_GetDevName(h, True)
    ; y := Format("{:i}", "0x" y)

    i := A.indexOf(InputDevices, h)

    ; Wrap around 16
    if (x < 0) {
        x := 15 + x
    }
    x := toHex(x)
    ; x := str2hex(x)

    if (y < 0) {
        y := 15 + y
    }
    y := toHex(y)
    
    If (i == -1) {
        ; Register new device
        InputDevices.push(h)
        LV_Add("", i, h, x, y, A_TickCount, devinfo)
    } Else {
        
        LV_Modify(i,, i, h, x, y, A_TickCount, devinfo)
    }

    ; Send data to browser by executing js snippets
    if (i == 2) {
        Send {U+082%x%%y%}
        ; wdriver.ExecuteScript("console.log(" x ")")
        ; wdriver.ExecuteScript("document.getElementById('A').getElementsByClassName('posreceive-x')[0].setAttribute('value'," x ")")
        ; wdriver.ExecuteScript("document.getElementById('A').getElementsByClassName('posreceive-y')[0].setAttribute('value'," y ")")
        ; wdriver.ExecuteScript("document.getElementById('A').getElementsByClassName('posreceive-x')[0].setAttribute('count', 1)")
        ; wdriver.ExecuteScript("document.getElementById('A').getElementsByClassName('posreceive-y')[0].setAttribute('count', 1)")
        ; wdriver.ExecuteScript("document.getElementById('A').getElementsByClassName('posreceive-pending')[0].click()")
        ; wdriver.ExecuteScript("document.getElementById('A').getElementsByClassName('posreceive-pending')[0].value += 1")
    }
}