sub setFields()
    json = m.top.json

    m.top.id = json.id
    m.top.Title = json.name
    m.top.Type = "Photo"

    setPoster()
end sub

sub setPoster()
    if m.top.image <> invalid
        m.top.posterURL = m.top.image.url
    else

        if m.top.json.ImageTags.Primary <> invalid
            imgParams = { "maxHeight": 440, "maxWidth": 295, "Tag": m.top.json.ImageTags.Primary }
            m.top.posterURL = api_API().items.getimageurl(m.top.json.id, "Primary", 0, imgParams)
        else if m.top.json.BackdropImageTags[0] <> invalid
            imgParams = { "maxHeight": 440, "Tag": m.top.json.BackdropImageTags[0] }
            m.top.posterURL = api_API().items.getimageurl(m.top.json.id, "Backdrop", 0, imgParams)
        else if m.top.json.ParentThumbImageTag <> invalid and m.top.json.ParentThumbItemId <> invalid
            imgParams = { "maxHeight": 440, "maxWidth": 295, "Tag": m.top.json.ParentThumbImageTag }
            m.top.posterURL = api_API().items.getimageurl(m.top.json.ParentThumbItemId, "Thumb", 0, imgParams)
        end if

        ' Add Backdrop Image
        if m.top.json.BackdropImageTags[0] <> invalid
            imgParams = { "maxHeight": 720, "maxWidth": 1280, "Tag": m.top.json.BackdropImageTags[0] }
            m.top.backdropURL = api_API().items.getimageurl(m.top.json.id, "Backdrop", 0, imgParams)
        end if

    end if
end sub
