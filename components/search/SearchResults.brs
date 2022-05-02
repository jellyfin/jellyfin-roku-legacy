sub init()
    m.top.optionsAvailable = false
    Print "Viewing Search Results XML"
    m.SearchSpinner = m.top.findnode("SearchSpinner")
    m.searchSelect = m.top.findnode("searchSelect")
    
end sub

sub SearchMedias()
    m.SearchSpinner.visible = true
    query = m.top.SearchAlpha
    ' This appears to be done differently on the web now
    ' For each potential type, a separate query is done:
    ' varying item types, and artists, and people
    print m.top.SearchAlpha
    results = SearchMedia(query)
    m.SearchSpinner.visible = false
    m.searchSelect.itemdata = results
    m.searchSelect.query = m.top.SearchAlpha
end sub