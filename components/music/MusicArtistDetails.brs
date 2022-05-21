sub init()
    m.top.optionsAvailable = false
    setupMainNode()
end sub

sub setupMainNode()
    main = m.top.findNode("toplevel")
    main.translation = [96, 175]
end sub

' Event fired when page data is loaded
sub pageContentChanged()
    item = m.top.pageContent

    ' Populate scene data
    setScreenTitle(item.json)
    setPosterImage(item.posterURL)
    setOnScreenTextValues(item.json)
end sub

sub setScreenTitle(json)
    if isValid(json)
        m.top.overhangTitle = json.name
    end if
end sub

sub setPosterImage(posterURL)
    if isValid(posterURL)
        m.top.findNode("artistImage").uri = posterURL
    end if
end sub

' Populate on screen text variables
sub setOnScreenTextValues(json)
    if isValid(json)
        setFieldTextValue("overview", json.overview)
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    return false
end function
