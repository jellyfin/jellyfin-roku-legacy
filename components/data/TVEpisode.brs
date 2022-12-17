sub setFields()
    json = m.top.json

    m.top.id = json.id
    m.top.Title = json.name
    m.top.Description = json.overview
    m.top.favorite = json.UserData.isFavorite
    m.top.watched = json.UserData.played
    m.top.Type = json.Type

    setPoster()
end sub

sub setPoster()
    if m.top.image <> invalid
        m.top.posterURL = m.top.image.url
    else if m.top.json.ImageTags.Primary <> invalid
        imgParams = { "maxHeight": 440, "maxWidth": 295 }
        m.top.posterURL = api_API().items.getimageurl(m.top.json.id, "Primary", 0, imgParams)
    end if
end sub
