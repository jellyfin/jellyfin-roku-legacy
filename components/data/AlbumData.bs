sub setFields()
    datum = m.top.json

    m.top.id = datum.id
    m.top.title = datum.name
end sub

