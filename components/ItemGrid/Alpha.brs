sub init()
    m.top.visible = true
    m.Alphamenu = m.top.findNode("Alphamenu")
    m.Alphamenu.focusable = true
    m.Alphatext = m.top.findNode("alphatext")
    m.focusedChild = m.top.findNode("focusedChild")
    m.Alphamenu.focusedFont.size = 25
    m.Alphamenu.font.size = 25
end sub

function onKeyEvent(key as string, press as boolean) as boolean

    if not press then return false

    if key = "down"
        m.AlphaMenu.setFocus(true)
        return true
    else if key = "right"
        m.AlphaMenu.setFocus(true)
        return true
    else if key = "up"
        if m.selectedFocusedIndex <> invalid and m.selectedFocusedIndex < m.buttonCount - 1 then m.selectedFocusedIndex = m.selectedFocusedIndex + 1
        m.top.focusedIndex = m.selectedFocusedIndex
        return true
    else if key = "OK"
        child = m.Alphatext.getChild(m.Alphamenu.itemFocused)
        m.top.itemAlphaSelected = child.title

        if child.title <> "x"
            existing = m.Alphatext.getChild(0)
            if existing.title <> "x"
                clear_all = CreateObject("roSGNode", "ContentNode")
                clear_all.title = "x"
                m.Alphatext.insertChild(clear_all, 0)
            end if
        end if
        if child.title = "x"
            m.Alphatext.removeChildIndex(0)
        end if
        return true
    end if
    return false
end function