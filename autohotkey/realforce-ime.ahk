#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook()
InstallMouseHook()
A_MenuMaskKey := "vkE8"

; REALFORCE for Mac R2 US TKL. Command key codes depend on keyboard mode.
; Virtual-key reference: https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
; Keyboard manual: https://www.realforce.co.jp/en/products/discontinued/R2TL-USVM-WH/REALFORCE_TKL_for_Mac_US_Manual.pdf

tapLimitMs := 500
tapState := Map(
    "LWin", { pending: false, startedAt: 0, cancelled: false },
    "RWin", { pending: false, startedAt: 0, cancelled: false },
    "AppsKey", { pending: false, startedAt: 0, cancelled: false }
)

; Keep keyboard input visible while observing physical key presses.
keyWatcher := InputHook("VL0")
keyWatcher.KeyOpt("{All}", "N")
keyWatcher.MinSendLevel := 101 ; Ignore keys sent by this script.
keyWatcher.OnKeyDown := CancelForOtherKey
keyWatcher.Start()

; Left Command reports LWin. Pass it through for Win shortcuts.
~*LWin::BeginTap("LWin", 0x5B)
~*LWin Up::EndTap("LWin", "{vk1A}")

; Right Command can report RWin. Pass it through for Win shortcuts.
~*RWin::BeginTap("RWin", 0x5C)
~*RWin Up::EndTap("RWin", "{vk16}")

; Retain AppsKey support for keyboard modes that report it for Right Command.
*AppsKey::BeginTap("AppsKey", 0x5D)
*AppsKey Up::EndTap("AppsKey", "{vk16}")

; Physical mouse input also makes a key press ineligible as a tap.
~*LButton::CancelAllTaps()
~*RButton::CancelAllTaps()
~*MButton::CancelAllTaps()
~*XButton1::CancelAllTaps()
~*XButton2::CancelAllTaps()
~*WheelUp::CancelAllTaps()
~*WheelDown::CancelAllTaps()
~*WheelLeft::CancelAllTaps()
~*WheelRight::CancelAllTaps()

BeginTap(key, selfVk) {
    global tapState

    state := tapState[key]
    if state.pending
        return ; Ignore key-repeat events.

    CancelOtherTap(key)

    if key = "LWin" || key = "RWin"
        Send "{Blind}{vkE8}" ; Prevent a lone Win press from opening Start.

    state.startedAt := A_TickCount
    state.pending := true
    state.cancelled := HasOtherHeldKey(selfVk)
}

EndTap(key, imeKey) {
    global tapLimitMs, tapState

    state := tapState[key]
    if !state.pending {
        state.cancelled := false
        return
    }

    isTap := !state.cancelled
        && A_TickCount - state.startedAt <= tapLimitMs
        && A_PriorKey = key

    state.pending := false
    state.cancelled := false

    if isTap
        Send imeKey
}

CancelForOtherKey(hook, vk, sc) {
    if (vk = 0x5B && IsPending("LWin"))
        || (vk = 0x5C && IsPending("RWin"))
        || (vk = 0x5D && IsPending("AppsKey"))
        return ; Ignore repeats of a pending key.

    CancelAllTaps()
}

IsPending(key) {
    global tapState
    return tapState[key].pending
}

CancelOtherTap(currentKey) {
    global tapState
    for key, state in tapState {
        if key != currentKey && state.pending
            state.cancelled := true
    }
}

CancelAllTaps() {
    global tapState
    for _, state in tapState {
        if state.pending
            state.cancelled := true
    }
}

HasOtherHeldKey(selfVk) {
    Loop 0xFE {
        vk := A_Index
        if vk != selfVk && GetKeyState(Format("vk{:02X}", vk), "P")
            return true
    }
    return false
}
