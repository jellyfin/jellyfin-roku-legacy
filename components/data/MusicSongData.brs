sub setFields()
    datum = m.top.json

    m.top.id = datum.id
    m.top.title = datum.name
    m.top.overview = datum.overview
    m.top.trackNumber = datum.IndexNumber
    m.top.length = datum.RunTimeTicks
end sub

sub setPoster()
    if m.top.image <> invalid
        m.top.posterURL = m.top.image.url
    else
        m.top.posterURL = ""
    end if
end sub
