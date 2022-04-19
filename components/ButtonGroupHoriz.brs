sub init()
    m.top.layoutDirection = "horiz"
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "right"
        i = m.top.buttonFocused
        target = i + 1
        if target >= m.top.getChildCount() then return false
        m.top.focusButton = target
        return true
    else if key = "left"
        i = m.top.buttonFocused
        target = i - 1
        if target < 0 then return false
        m.top.focusButton = target
        return true
    else if key = "up" or key = "down"
        m.top.escape = key
        return true
    end if

    return false
end function
