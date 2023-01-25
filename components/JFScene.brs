sub init()
    m.top.backgroundColor = "#262626" '"#101010"
    m.top.backgroundURI = ""
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "back"
        m.global.sceneManager.callFunc("popScene")
        return true
    else if key = "options"
        group = m.global.sceneManager.callFunc("getActiveScene")
        if isValid(group) and isValid(group.optionsAvailable) and group.optionsAvailable
            group.lastFocus = group.focusedChild
            panel = group.findNode("options")
            panel.visible = true
            panel.findNode("panelList").setFocus(true)
        end if
        return true
    end if

    return false
end function
