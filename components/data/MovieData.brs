import "pkg:/source/api/Image.brs"
import "pkg:/source/api/baserequest.brs"
import "pkg:/source/utils/config.brs"
import "pkg:/source/utils/misc.brs"

sub setFields()
    json = m.top.json

    m.top.id = json.id
    m.top.Title = json.name
    m.top.Description = json.overview
    m.top.favorite = json.UserData.isFavorite
    m.top.watched = json.UserData.played
    m.top.Type = "Movie"

    if isValid(json.MediaSourceCount) and json.MediaSourceCount > 1
        if isValid(json.MediaSources)
            m.top.mediaSources = []
            for each source in json.MediaSources
                m.top.mediaSources.push(source)
            end for
        end if
    end if

    if json.ProductionYear <> invalid
        m.top.SubTitle = json.ProductionYear
    end if

    if json.OfficialRating <> invalid and json.OfficialRating <> ""
        m.top.Rating = json.OfficialRating
        if m.top.SubTitle <> ""
            m.top.SubTitle = m.top.SubTitle + " - " + m.top.Rating
        else
            m.top.SubTitle = m.top.Rating
        end if
    end if

    setPoster()
    setContainer()
end sub

sub setPoster()
    if m.top.image <> invalid
        m.top.posterURL = m.top.image.url
    else
        if isValid(m.top.json)
            if isValid(m.top.json.ImageTags) and isValid(m.top.json.ImageTags.Primary)
                imgParams = { "maxHeight": 440, "maxWidth": 295, "Tag": m.top.json.ImageTags.Primary }
                m.top.posterURL = ImageURL(m.top.json.id, "Primary", imgParams)
            else if isValid(m.top.json.BackdropImageTags) and isValid(m.top.json.BackdropImageTags[0])
                imgParams = { "maxHeight": 440, "Tag": m.top.json.BackdropImageTags[0] }
                m.top.posterURL = ImageURL(m.top.json.id, "Backdrop", imgParams)
            else if isValid(m.top.json.ParentThumbImageTag) and isValid(m.top.json.ParentThumbItemId)
                imgParams = { "maxHeight": 440, "maxWidth": 295, "Tag": m.top.json.ParentThumbImageTag }
                m.top.posterURL = ImageURL(m.top.json.ParentThumbItemId, "Thumb", imgParams)
            end if

            ' Add Backdrop Image
            if isValid(m.top.json.BackdropImageTags) and isValid(m.top.json.BackdropImageTags[0])
                imgParams = { "maxHeight": 720, "maxWidth": 1280, "Tag": m.top.json.BackdropImageTags[0] }
                m.top.backdropURL = ImageURL(m.top.json.id, "Backdrop", imgParams)
            end if
        end if
    end if
end sub

sub setContainer()
    json = m.top.json

    if json.mediaSources = invalid then return
    if json.mediaSources.count() = 0 then return

    m.top.container = json.mediaSources[0].container

    if m.top.container = invalid then m.top.container = ""

    if m.top.container = "m4v" or m.top.container = "mov"
        m.top.container = "mp4"
    end if
end sub
