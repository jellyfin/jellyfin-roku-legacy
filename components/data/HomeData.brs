sub setData()
    ' We keep json around just as a reference,
    ' but ideally everything should be going through one of the interfaces
    datum = m.top.json

    m.top.id = datum.id
    m.top.name = datum.name
    m.top.type = datum.type

    if datum.CollectionType = invalid
        m.top.CollectionType = datum.type
    else
        m.top.CollectionType = datum.CollectionType
    end if

    ' Set appropriate Images for Wide and Tall based on type

    if datum.type = "CollectionFolder" or datum.type = "UserView"
        params = { "maxHeight": 261, "maxWidth": 464 }
        m.top.thumbnailURL = ImageURL(datum.id, "Primary", params)
        m.top.widePosterUrl = m.top.thumbnailURL

        ' Add Icon URLs for display if there is no Poster
        if datum.CollectionType = "livetv"
            m.top.iconUrl = "pkg:/images/media_type_icons/live_tv_white.png"
        else if datum.CollectionType = "folders"
            m.top.iconUrl = "pkg:/images/media_type_icons/folder_white.png"
        end if

    else if datum.type = "Episode"
        imgParams = { "AddPlayedIndicator": datum.UserData.Played }
        imgParams_wide = { "AddPlayedIndicator": datum.UserData.Played }

        if datum.UserData.PlayedPercentage <> invalid
            imgParams.Append({ "PercentPlayed": datum.UserData.PlayedPercentage })
            imgParams_wide.Append({ "PercentPlayed": datum.UserData.PlayedPercentage })
        end if

        imgParams.Append({ "maxHeight": 261, "maxWidth": 464 })
        imgParams_wide.Append({ "maxHeight": 261, "maxWidth": 464 })

        m.top.thumbnailURL = ImageURL(datum.id, "Primary", imgParams)

        ' Add Wide Poster  (Series Backdrop)
        if datum.ParentBackdropImageTags <> invalid
            m.top.posterUrl = ImageURL(datum.ParentBackdropItemId, "Primary", imgParams)
            m.top.widePosterUrl = ImageURL(datum.ParentBackdropItemId, "Backdrop", imgParams_wide)
        end if

    else if datum.type = "Series"
        imgParams = { "fillHeight": 624, "fillWidth": 416, "quality": 96 }
        imgParams_wide = { "fillHeight": 374, "fillWidth": 664, "quality": 96 }

        if datum.UserData.UnplayedItemCount > 0
            imgParams["UnplayedCount"] = datum.UserData.UnplayedItemCount
        end if

        if datum.UserData.PlayedPercentage <> invalid
            imgParams.Append({ "PercentPlayed": datum.UserData.PlayedPercentage })
            imgParams_wide.Append({ "PercentPlayed": datum.UserData.PlayedPercentage })
        end if

        m.top.posterURL = ImageURL(datum.Id, "Primary", imgParams)

        ' Add Wide Poster  (Series Backdrop)
        if datum.ImageTags <> invalid and datum.imageTags.Thumb <> invalid
            m.top.widePosterUrl = ImageURL(datum.Id, "Thumb", imgParams_wide)
        else if datum.BackdropImageTags <> invalid
            m.top.widePosterUrl = ImageURL(datum.Id, "Backdrop", imgParams_wide)
        end if

    else if datum.type = "Movie"
        imgParams = { "fillHeight": 624, "fillWidth": 416, "quality": 96 }
        imgParams_wide = { "fillHeight": 374, "fillWidth": 664, "quality": 96 }

        if datum.UserData.PlayedPercentage <> invalid
            imgParams.Append({ "PercentPlayed": datum.UserData.PlayedPercentage })
            imgParams_wide.Append({ "PercentPlayed": datum.UserData.PlayedPercentage })
        end if

        imgParams.Append({ "maxHeight": 261, "maxWidth": 464 })
        imgParams_wide.Append({ "maxHeight": 261, "maxWidth": 464 })

        m.top.posterURL = ImageURL(datum.id, "Primary", imgParams)
        m.top.widePosterURL = ImageURL(datum.id, "Backdrop", imgParams_wide)

    else if datum.type = "Video"
        imgParams = { "fillHeight": 624, "fillWidth": 416, "quality": 96, AddPlayedIndicator: datum.UserData.Played }
        imgParams_wide = { "fillHeight": 374, "fillWidth": 664, "quality": 96, AddPlayedIndicator: datum.UserData.Played }

        if datum.UserData.PlayedPercentage <> invalid
            imgParams.Append({ "PercentPlayed": datum.UserData.PlayedPercentage })
            imgParams_wide.Append({ "PercentPlayed": datum.UserData.PlayedPercentage })
        end if

        imgParams.Append({ "maxHeight": 261, "maxWidth": 464 })
        imgParams_wide.Append({ "maxHeight": 261, "maxWidth": 464 })

        m.top.posterURL = ImageURL(datum.id, "Primary", imgParams)
        m.top.widePosterURL = ImageURL(datum.id, "Backdrop", imgParams_wide)
    else if datum.type = "MusicAlbum" or datum.type = "Audio"
        imgParams = { "fillHeight": 624, "fillWidth": 416, "quality": 96, AddPlayedIndicator: datum.UserData.Played }
        m.top.thumbnailURL = ImageURL(datum.id, "Primary", imgParams)
        m.top.widePosterUrl = ImageURL(datum.id, "Backdrop", imgParams)
        m.top.posterUrl = ImageURL(datum.id, "Primary", imgParams)

    else if datum.type = "TvChannel" or datum.type = "Channel"
        params = { "maxHeight": 261, "maxWidth": 464 }
        m.top.posterUrl = ImageURL(datum.id, "Primary", params)
        m.top.iconUrl = "pkg:/images/media_type_icons/live_tv_white.png"
    end if

end sub
