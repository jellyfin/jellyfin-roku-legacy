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

        if child.title = m.top.itemAlphaSelected
            m.top.itemAlphaSelected = ""
            m.Alphamenu.focusFootprintBitmapUri = ""
        else
            m.Alphamenu.focusFootprintBitmapUri = "pkg:/images/white.9.png"
            m.top.itemAlphaSelected = child.title
        end if
        return true
    end if
    return false
end function