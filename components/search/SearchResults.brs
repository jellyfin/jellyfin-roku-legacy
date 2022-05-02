sub init()
    m.top.optionsAvailable = false
    Print "Viewing Search Results XML"
    m.SearchSpinner = m.top.findnode("SearchSpinner")
    m.searchSelect = m.top.findnode("searchSelect")
    'm.SearchAlphaSelected = m.top.findNode("SearchBox")
    'm.data = CreateObject("roSGNode", "ContentNode")
    'm.SearchAlphaSelected = m.data

    'm.SearchAlphaSelected.observeField("SearchAlpha", "SearchMedias")
    'm.SearchAlphaSelected = m.top.findNode("SearchAlpha")
    'print m.SearchAlphaSelected
end sub

sub SearchMedias()
    m.SearchSpinner.visible = true
    ' This appears to be done differently on the web now
    ' For each potential type, a separate query is done:
    ' varying item types, and artists, and people
    print m.top.SearchAlpha
    results = SearchMedia(m.top.SearchAlpha)
    m.SearchSpinner.visible = false
    m.searchSelect = results
    m.searchSelect.query = m.top.SearchAlph
end sub