/*
快速晃动指针时将指针尺寸调大
*/

; ==== 配置 ====
shakeThreshold := 800         ; px/s 实际距离速度阈值
shakeDuration  := 500         ; ms，快速移动持续多久才触发
checkInterval  := 50          ; ms，采样频率
restoreDelay   := 5000        ; ms, 恢复初始大小的时间
cursorScale    := 10.0        ; 指针放大倍率

MouseGetPos(&lastX, &lastY)
lastTime := A_TickCount
shakeStart := 0
isShaking := false
dpi := GetSystemDPI()

; 主循环计时器
SetTimer(CheckMouseMovement, checkInterval)

CheckMouseMovement() {
    global lastX, lastY, lastTime, shakeStart, isShaking, dpi
    MouseGetPos(&currX, &currY)
    currTime := A_TickCount

    dx := currX - lastX
    dy := currY - lastY
    dt := currTime - lastTime

    ; 转换为物理像素距离
    dist := Sqrt((dx ** 2) + (dy ** 2)) * (96 / dpi)
    speed := dist / (dt / 1000) ; px/s

    ; 快速晃动检测逻辑
    if (speed > shakeThreshold) {
        if (shakeStart = 0)
            shakeStart := currTime
        else if (!isShaking && (currTime - shakeStart >= shakeDuration)) {
            isShaking := true
            OnShakeDetected()
        }
    } else {
        shakeStart := 0
        isShaking := false
    }

    lastX := currX
    lastY := currY
    lastTime := currTime
}

; 快速晃动触发操作
OnShakeDetected() {
    ToolTip("`n`t`t我在这里！`t`t`n ")
    baseSize := RegRead("HKEY_CURRENT_USER\Control Panel\Cursors", "CursorBaseSize")
    DllCall("SystemParametersInfo", "Int", 0x2029, "Int", 0, "Ptr", cursorScale * baseSize, "Int", 0x01)
    SetTimer(() => ToolTip(), -1000)  ; 1 秒后清除提示
    Sleep(restoreDelay)
    DllCall("SystemParametersInfo", "Int", 0x2029, "Int", 0, "Ptr", baseSize, "Int", 0x01)
}

; 获取当前显示器 DPI
GetSystemDPI() {
    hDC := DllCall("GetDC", "ptr", 0, "ptr")
    dpi := DllCall("GetDeviceCaps", "ptr", hDC, "int", 88, "int") ; LOGPIXELSX = 88
    DllCall("ReleaseDC", "ptr", 0, "ptr", hDC)
    return dpi
}