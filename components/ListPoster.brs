sub init()
    m.title = m.top.findNode("title")
    m.staticTitle = m.top.findNode("staticTitle")
    m.poster = m.top.findNode("poster")

    m.backdrop = m.top.findNode("backdrop")

    m.deviceInfo = CreateObject("roDeviceInfo")

    ' Randmomise the background colors
    posterBackgrounds = m.global.constants.poster_bg_pallet
    m.backdrop.color = posterBackgrounds[rnd(posterBackgrounds.count()) - 1]

    updateSize()
end sub

sub updateSize()

    image = invalid
    if m.top.itemContent <> invalid and m.top.itemContent.image <> invalid
        image = m.top.itemContent.image
    end if

    if image = invalid
        m.backdrop.visible = true
    else
        m.backdrop.visible = false
    end if

    ' TODO - abstract this in case the parent doesnt have itemSize
    maxSize = m.top.getParent().itemSize

    ' Always reserve the bottom for the Poster Title
    m.title.maxWidth = maxSize[0]
    m.title.height = 40
    m.title.translation = [0, int(maxSize[1]) - m.title.height + 5]

    m.staticTitle.width = maxSize[0]
    m.staticTitle.height = m.title.height
    m.staticTitle.translation = m.title.translation

    m.poster.width = int(maxSize[0]) - 4
    m.poster.height = int(maxSize[1]) - m.title.height 'Set poster height to available space

    m.backdrop.width = m.poster.width
    m.backdrop.height = m.poster.height

end sub

sub itemContentChanged() as void
    m.poster = m.top.findNode("poster")
    itemData = m.top.itemContent
    m.title.text = itemData.title
    if itemData.json.lookup("Type") = "Episode" and itemData.json.IndexNumber <> invalid
        m.title.text = StrI(itemData.json.IndexNumber) + ". " + m.title.text
    end if
    m.staticTitle.text = m.title.text

    imageUrl = itemData.posterURL

    if get_user_setting("ui.tvshows.blurunwatched") = "true"

        if itemData.json.lookup("Type") = "Episode"
            if not itemData.json.userdata.played
                imageUrl = imageUrl + "&blur=15"
            end if
        end if
    end if

    m.poster.uri = imageUrl

    updateSize()
end sub

'
' Enable title scrolling based on item Focus
sub focusChanged()

    if m.top.itemHasFocus = true
        m.title.repeatCount = -1
        m.staticTitle.visible = false
        m.title.visible = true

        ' text to speech for accessibility
        if m.deviceInfo.IsAudioGuideEnabled() = true
            txt2Speech = CreateObject("roTextToSpeech")
            txt2Speech.Flush()
            txt2Speech.Say(m.title.text)
        end if

    else
        m.title.repeatCount = 0
        m.staticTitle.visible = true
        m.title.visible = false
    end if

end sub
