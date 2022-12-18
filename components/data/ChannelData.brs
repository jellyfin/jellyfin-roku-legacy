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
        imgParams = { "maxHeight": 60, "Tag": m.top.json.ImageTags.Primary }
        m.top.hdsmalliconurl = api_API().items.getimageurl(m.top.json.id, "Primary", 0, imgParams)

        imgParams = { "maxHeight": 440, "maxWidth": 295, "Tag": m.top.json.ImageTags.Primary }
        m.top.posterURL = api_API().items.getimageurl(m.top.json.id, "Primary", 0, imgParams)
    end if
end sub
