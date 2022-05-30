sub init()
    m.top.functionName = "search"
end sub

sub search()
    if m.top.query <> invalid and m.top.query <> ""
        m.top.results = searchMedia(m.top.query)
    end if
end sub
