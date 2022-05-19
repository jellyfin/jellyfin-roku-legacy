sub init()
    m.top.optionsAvailable = false
    m.SearchSpinner = m.top.findnode("SearchSpinner")
    m.searchSelect = m.top.findnode("searchSelect")
    m.searchTask = CreateObject("roSGNode", "SearchTask")

end sub

sub SearchMedias()
    query = m.top.SearchAlpha

    'if search task is running and user selectes another letter stop the search and load the next letter

    m.searchTask.control = "stop"

    m.SearchSpinner.visible = true
    m.searchTask.observeField("results", "loadResults")
    m.searchTask.query = query
    m.searchTask.control = "RUN"

end sub

sub loadResults()
    m.searchTask.unobserveField("results")

    m.SearchSpinner.visible = false
    m.searchSelect.itemdata = m.searchTask.results
    m.searchSelect.query = m.top.SearchAlpha
    print "Search Results: " m.searchSelect.itemdata
end sub

function onKeyEvent(key as string, press as boolean) as boolean

    m.SearchAlphabox = m.top.findNode("search_Key")

    if key = "left" and m.searchSelect.isinFocusChain() and (m.searchSelect.currFocusColumn = -1 or m.searchSelect.currFocusColumn = 0)
        m.SearchAlphabox.setFocus(true)
        return true
    else if key = "right"
        m.searchSelect.setFocus(true)
        return true
    end if
    return false

end function