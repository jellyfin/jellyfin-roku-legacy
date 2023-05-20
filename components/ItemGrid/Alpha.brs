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

    if key = "up"
        if m.Alphamenu.itemFocused = 0
            m.Alphamenu.jumpToItem = m.Alphamenu.numRows - 1
            return true
        end if
    end if

    if key = "down"
        if m.Alphamenu.itemFocused = m.Alphamenu.numRows - 1
            m.Alphamenu.jumpToItem = 0
            return true
        end if
    end if

    return false
end function
