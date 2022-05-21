sub init()
    m.top.optionsAvailable = false
    main = m.top.findNode("toplevel")
    main.translation = [96, 175]

    m.buttons = m.top.findNode("buttons")
    m.buttons.buttons = [tr("Previous"), tr("Play/Pause"), tr("Next")]
    m.buttons.observeField("focusedIndex", "buttonFocusChanged")

    m.buttons.selectedIndex = 1
    m.buttons.focusedIndex = 1
    m.buttons.setFocus(true)

    m.top.audio = createObject("RoSGNode", "Audio")
    m.top.audio.observeField("contentIndex", "audioIndexChanged")
end sub

sub audioIndexChanged()
    itemContentChanged()
end sub

' Switch menu shown when button focus changes
sub buttonFocusChanged()
    if m.buttons.focusedIndex = m.selectedItem then return
    m.selectedItem = m.buttons.focusedIndex
end sub

sub playClicked()
    if m.top.audio.state = "playing"
        m.top.audio.control = "pause"
    else if m.top.audio.state = "paused"
        m.top.audio.control = "resume"
    end if
end sub

sub previousClicked()
    if m.top.audio.contentIndex > 0
        m.top.audio.nextContentIndex = m.top.audio.contentIndex - 1
        m.top.audio.control = "skipcontent"
    end if
end sub

sub nextClicked()
    m.top.audio.control = "skipcontent"
end sub

' Set values for displayed values on screen
sub itemContentChanged()
    if m.top.audio.contentIndex = -1 then return

    item = m.top.itemContent[m.top.audio.contentIndex]

    m.top.findNode("musicartistPoster").uri = item.posterURL
    m.top.overhangTitle = item.json.AlbumArtist + " / " + item.json.name

    setFieldText("numberofsongs", "Track " + stri(m.top.audio.contentIndex + 1) + "/" + stri(m.top.itemContent.count()))
    setFieldText("artist", item.json.Artists[0])
    setFieldText("album", item.json.album)
    setFieldText("song", item.json.name)

    ' Add Backdrop Image
    if m.top.backgroundContent[m.top.audio.contentIndex] <> invalid
        m.top.findNode("backdrop").uri = m.top.backgroundContent[m.top.audio.contentIndex]
    end if
end sub

sub setFieldText(field, value)
    node = m.top.findNode(field)
    if node = invalid or value = invalid then return

    ' Handle non strings... Which _shouldn't_ happen, but hey
    if type(value) = "roInt" or type(value) = "Integer"
        value = str(value).trim()
    else if type(value) = "roFloat" or type(value) = "Float"
        value = str(value).trim()
    else if type(value) <> "roString" and type(value) <> "String"
        value = ""
    end if

    node.text = value
end sub

function onKeyEvent(key as string, press as boolean) as boolean

    if press and key = "play"
        playClicked()
        return true
    else if press and key = "back"
        m.top.audio.control = "stop"
    else if press and key = "rewind"
        previousClicked()
        return true
    else if press and key = "fastforward"
        nextClicked()
        return true
    else if key = "OK" and m.top.findNode("buttons").hasFocus()
        if m.buttons.buttons[m.selectedItem] = tr("Play/Pause")
            playClicked()
            return true
        else if m.buttons.buttons[m.selectedItem] = tr("Previous")
            previousClicked()
            return true
        else if m.buttons.buttons[m.selectedItem] = tr("Next")
            nextClicked()
            return true
        end if
    end if

    return false
end function
