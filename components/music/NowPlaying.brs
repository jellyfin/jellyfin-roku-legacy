sub init()
    m.top.optionsAvailable = false

    setupMainNode()
    setupAudioNode()
    setupButtons()
end sub

sub setupMainNode()
    main = m.top.findNode("toplevel")
    main.translation = [96, 175]
end sub

sub setupAudioNode()
    m.top.audio = createObject("RoSGNode", "Audio")
    m.top.audio.observeField("contentIndex", "audioIndexChanged")
end sub

sub setupButtons()
    m.buttons = m.top.findNode("buttons")
    m.buttons.buttons = [tr("Previous"), tr("Play/Pause"), tr("Next")]

    m.buttons.selectedIndex = 1
    m.buttons.focusedIndex = 1
    m.buttons.setFocus(true)
end sub

sub audioIndexChanged()
    pageContentChanged()
end sub

function playAction() as boolean
    if m.top.audio.state = "playing"
        m.top.audio.control = "pause"
    else if m.top.audio.state = "paused"
        m.top.audio.control = "resume"
    end if

    return true
end function

function previousClicked() as boolean
    if m.top.audio.contentIndex > 0
        m.top.audio.nextContentIndex = m.top.audio.contentIndex - 1
        m.top.audio.control = "skipcontent"
    end if

    return true
end function

function nextClicked() as boolean
    if m.top.audio.contentIsPlaylist
        m.top.audio.control = "skipcontent"
    end if
    
    return true
end function

' Update values on screen when page content changes
sub pageContentChanged()
    ' If audio isn't playing yet, skip because we have nothing to update
    if m.top.audio.contentIndex = -1 then return

    item = m.top.pageContent[m.top.audio.contentIndex]

    setPosterImage(item.posterURL)
    setScreenTitle(item.json)
    setOnScreenTextValues(item.json)
    setBackdropImage()
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
        setFieldTextValue("numberofsongs", "Track " + stri(m.top.audio.contentIndex + 1) + "/" + stri(m.top.pageContent.count()))
        setFieldTextValue("artist", json.Artists[0])
        setFieldTextValue("album", json.album)
        setFieldTextValue("song", json.name)
    end if
end sub

' Add backdrop image to screen
sub setBackdropImage()
    if isValid(m.top.backgroundContent[m.top.audio.contentIndex])
        m.top.findNode("backdrop").uri = m.top.backgroundContent[m.top.audio.contentIndex]
    end if
end sub

' Process key press events
function onKeyEvent(key as string, press as boolean) as boolean

    ' Key bindings for remote control buttons
    if press
        if key = "play"
            return playAction()
        else if key = "back"
            m.top.audio.control = "stop"
        else if key = "rewind"
            return previousClicked()
        else if key = "fastforward"
            return nextClicked()
        end if

        return false
    end if

    ' Key bindings for button group
    if m.top.findNode("buttons").hasFocus()
        if key = "OK"
            if m.buttons.buttons[m.buttons.focusedIndex] = tr("Play/Pause")
                return playAction()
            else if m.buttons.buttons[m.buttons.focusedIndex] = tr("Previous")
                return previousClicked()
            else if m.buttons.buttons[m.buttons.focusedIndex] = tr("Next")
                return nextClicked()
            end if
        end if
    end if

    return false
end function
