sub init()
    m.top.visible = true

    m.top.observeField("rowItemSelected", "onRowItemSelected")
    print "rowselected = " rowItemSelected
    ' Set up alpha Task
    
end sub


function onKeyEvent(key as string, press as boolean) as boolean
    if key = "down"
        print "KeyDown"
    end if

end function