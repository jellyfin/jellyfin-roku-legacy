sub init()
    m.top.functionName = "search"
end sub

sub search()
    if m.top.query <> invalid
        Print "Searching with: " m.top.query
        m.top.results = SearchMedia(m.top.query)
    end if
end sub
