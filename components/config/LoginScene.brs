sub init()
    m.top.setFocus(true)
    m.top.optionsAvailable = false
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    ' Returns true if user navigates to a new focusable element
    if not press then return false

    list = m.top.findNode("configOptions")
    checkbox = m.top.findNode("onOff")
    submit = m.top.findNode("submit")
    quickConnect = m.top.findNode("quickConnect")
    if key = "back"
        m.top.backPressed = true
    else if key = "down" and checkbox.focusedChild = invalid and submit.focusedChild = invalid
        limit = list.content.getChildren(-1, 0).count() - 1

        if limit = list.itemFocused
            checkbox.setFocus(true)
            return true
        end if
    else if key = "down" and submit.focusedChild = invalid
        submit.setFocus(true)
        return true
    else if key = "up" and submit.focusedChild <> invalid or quickConnect.focusedChild <> invalid
        checkbox.setFocus(true)
        return true
    else if key = "up" and checkbox.focusedChild <> invalid
        list.setFocus(true)
        return true
    else if key = "right" and submit.focusedChild <> invalid
        quickConnect.setFocus(true)
        return true
    else if key = "left" and quickConnect.focusedChild <> invalid
        submit.setFocus(true)
        return true
    end if
    return false
end function
