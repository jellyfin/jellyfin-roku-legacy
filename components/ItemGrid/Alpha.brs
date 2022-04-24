sub init()
    m.top.visible = true
    m.AlphaList.focusable = true
   ' m.top.observeField("rowItemSelected", "onRowItemSelected")
    'print "rowselected = " rowItemSelected
    ' Set up alpha Task
    m.AlphaList = m.top.findNode("Alphamenu")
    m.alphatext = m.top.findNode("alphatext")

    m.AlphaList.observeField("focusedChild", "focusChanged")
    m.AlphaList.checkedItem = 4
    m.AlphaList.focusRow = 4
    m.AlphaList.setFocus(true)
    
    
end sub

sub selectedIndexChanged()
    m.selectedFocusedIndex = m.top.focusedChild()
end sub

function onKeyEvent(key as string, press as boolean) as boolean

    if not press then return false

    if key = "down"
        if m.selectedFocusedIndex > 0 then m.selectedFocusedIndex = m.selectedFocusedIndex - 1
        m.top.focusedIndex = m.selectedFocusedIndex
        return true
    else if key = "up"
        if m.selectedFocusedIndex < m.buttonCount - 1 then m.selectedFocusedIndex = m.selectedFocusedIndex + 1
        m.top.focusedIndex = m.selectedFocusedIndex
        return true
    else if key = "OK"
        m.top.selectedIndex = m.selectedFocusedIndex
        return true
    end if
    return false
end function
