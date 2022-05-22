sub init()
    m.top.optionsAvailable = false
    setupMainNode()

    m.playAlbum = m.top.findNode("playAlbum")
    m.songList = m.top.findNode("songList")

    m.spinner = m.top.findNode("spinner")
    m.spinner.visible = false
end sub

sub setupMainNode()
    main = m.top.findNode("toplevel")
    main.translation = [96, 175]
end sub

' Set values for displayed values on screen
sub pageContentChanged()
    item = m.top.pageContent

    setPosterImage(item.posterURL)
    setScreenTitle(item.json)
    setOnScreenTextValues(item.json)

    ' Only 1 song shown, so hide Play Album button
    if item.json.ChildCount = 1
        m.top.findNode("playAlbum").visible = false
    end if
end sub

' Set poster image on screen
sub setPosterImage(posterURL)
    if isValid(posterURL)
        m.top.findNode("albumCover").uri = posterURL
    end if
end sub

' Set screen's title text
sub setScreenTitle(json)
    newTitle = ""
    if isValid(json)
        if isValid(json.AlbumArtist)
            newTitle = json.AlbumArtist
        end if
        if isValid(json.AlbumArtist) and isValid(json.name)
            newTitle = newTitle + " / "
        end if
        if isValid(json.name)
            newTitle = newTitle + json.name
        end if
    end if
    m.top.overhangTitle = newTitle
end sub

' Populate on screen text variables
sub setOnScreenTextValues(json)
    if isValid(json)
        setFieldTextValue("overview", json.overview)
        setFieldTextValue("numberofsongs", stri(json.ChildCount) + " Tracks")

        if type(json.ProductionYear) = "roInt"
            setFieldTextValue("released", "Released " + stri(json.ProductionYear))
        end if

        if json.genres.count() > 0
            setFieldTextValue("genres", json.genres.join(", "))
        end if

        if type(json.RunTimeTicks) = "LongInteger"
            setFieldTextValue("runtime", stri(getMinutes(json.RunTimeTicks)) + " mins")
        end if
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    ' Play Album is hidden, so there are no navigation needs here
    if m.top.pageContent.json.ChildCount = 1
        return false
    end if

    if key = "right" and m.playAlbum.hasFocus()
        m.songList.setFocus(true)
        return true
    else if key = "left" and m.songList.hasFocus()
        m.playAlbum.setFocus(true)
        return true
    end if

    return false
end function

sub OnScreenHidden()
    m.spinner.visible = false
end sub