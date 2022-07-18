sub setFields()
    json = m.top.json
    m.top.id = json.id
    m.top.title = json.name
    m.top.live = true
    m.top.Type = "TvChannel"
    setPoster()
end sub

sub setPoster()
    if m.top.image <> invalid
        m.top.posterURL = m.top.image.url
    else if m.top.json.ImageTags <> invalid and m.top.json.ImageTags.Primary <> invalid
        imgParams = { "maxHeight": 60 }
        m.top.hdsmalliconurl = ImageURL(m.top.json.id, "Primary", imgParams)

        imgParams = { "maxHeight": 440, "maxWidth": 295 }
        m.top.posterURL = ImageURL(m.top.json.id, "Primary", imgParams)
    end if
end sub
