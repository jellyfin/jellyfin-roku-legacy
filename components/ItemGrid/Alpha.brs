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

    if key = "OK"
        child = m.Alphatext.getChild(m.Alphamenu.itemFocused)

        if child.title = m.top.itemAlphaSelected
            m.top.itemAlphaSelected = ""
            m.Alphamenu.focusFootprintBitmapUri = ""
        else
            m.Alphamenu.focusFootprintBitmapUri = "pkg:/images/white.png"
            m.top.itemAlphaSelected = child.title
        end if
        return true
    end if
    return false
end function