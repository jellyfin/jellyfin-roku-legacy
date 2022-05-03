sub init()
    m.top.optionsAvailable = false
    Print "Viewing Search Results XML"
    m.SearchSpinner = m.top.findnode("SearchSpinner")
    m.searchSelect = m.top.findnode("searchSelect")

    m.searchTask = CreateObject("roSGNode", "SearchTask")
end sub

sub SearchMedias()
    m.SearchSpinner.visible = true
    query = m.top.SearchAlpha
    ' This appears to be done differently on the web now
    ' For each potential type, a separate query is done:
    ' varying item types, and artists, and people
    print m.top.SearchAlpha

    m.searchTask.observeField("results", "loadResults")
    m.searchTask.query = query
    m.searchTask.control = "Run"
end sub

sub loadResults()
    m.searchTask.unobserveField("results")

    m.SearchSpinner.visible = false

    ' TODO/FIXME:
    ' results come back, but they are off screen.
    ' when moving the focus to the results, you can't get back
    ' to the search keyboard.

    m.searchSelect.itemdata = m.searchTask.results
    m.searchSelect.query = m.top.SearchAlpha
end sub
