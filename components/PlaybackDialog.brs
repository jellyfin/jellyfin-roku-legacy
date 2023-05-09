function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "OK"
        m.top.close = true
        return true
    end if

    return false
end function
