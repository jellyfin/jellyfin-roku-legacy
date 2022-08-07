sub init()
    m.top.layoutDirection = "vert"
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "down"
        i = m.top.buttonFocused
        target = i + 1
        if target >= m.top.getChildCount() then return false
        m.top.focusButton = target
        return true
    else if key = "up"
        i = m.top.buttonFocused
        target = i - 1
        if target < 0 then return false
        m.top.focusButton = target
        return true
    else if key = "left" or key = "right"
        m.top.escape = key
        return true
    end if

    return false
end function
