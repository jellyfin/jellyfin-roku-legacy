function onKeyEvent(key as string) as boolean

    if key = "OK"
        m.top.close = true
        return true
    end if

    return false
end function
