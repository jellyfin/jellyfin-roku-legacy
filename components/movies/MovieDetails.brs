sub init()
    m.extrasGrp = m.top.findnode("extrasGrp")
    m.extrasGrid = m.top.findNode("extrasGrid")
    m.top.optionsAvailable = false

    m.audioOptions = m.top.findNode("audioOptions")
    m.videoOptions = m.top.findNode("videoOptions")

    m.main_group = m.top.findNode("main_group")

    main = m.top.findNode("main_group")
    main.translation = [96, 175]
    overview = m.top.findNode("overview")
    overview.width = 1920 - 96 - 300 - 96 - 30

    m.buttonGrp = m.top.findNode("buttons")
    m.buttonGrp.setFocus(true)

    m.top.observeField("itemContent", "itemContentChanged")
end sub

sub itemContentChanged()
    ' Updates video metadata
    item = m.top.itemContent
    itemData = item.json
    m.top.id = itemData.id
    m.top.findNode("moviePoster").uri = m.top.itemContent.posterURL

    ' Set default video source
    m.top.selectedVideoStreamId = itemData.MediaSources[0].id

    ' Find first Audio Stream and set that as default
    SetDefaultAudioTrack(itemData)

    ' Handle all "As Is" fields
    m.top.overhangTitle = itemData.name
    setFieldText("releaseYear", itemData.productionYear)
    setFieldText("officialRating", itemData.officialRating)
    setFieldText("overview", itemData.overview)

    if itemData.communityRating <> invalid
        setFieldText("communityRating", itemData.communityRating)
    else
        ' hide the star icon
        m.top.findNode("communityRatingGroup").visible = false
    end if

    if itemData.CriticRating <> invalid
        setFieldText("criticRatingLabel", itemData.criticRating)
        if itemData.CriticRating > 60
            tomato = "pkg:/images/fresh.png"
        else
            tomato = "pkg:/images/rotten.png"
        end if
        m.top.findNode("criticRatingIcon").uri = tomato
    else
        m.top.findNode("infoGroup").removeChild(m.top.findNode("criticRatingGroup"))
    end if

    if type(itemData.RunTimeTicks) = "LongInteger"
        setFieldText("runtime", stri(getRuntime()) + " mins")
        setFieldText("ends-at", tr("Ends at %1").Replace("%1", getEndTime()))
    end if

    if itemData.genres.count() > 0
        setFieldText("genres", tr("Genres") + ": " + itemData.genres.join(", "))
    end if

    ' show tags if there are no genres to display
    if itemData.genres.count() = 0 and itemData.tags.count() > 0
        setFieldText("genres", tr("Tags") + ": " + itemData.tags.join(", "))
    end if

    directors = []
    for each person in itemData.people
        if person.type = "Director"
            directors.push(person.name)
        end if
    end for
    if directors.count() > 0
        setFieldText("director", tr("Director") + ": " + directors.join(", "))
    end if

    if itemData.mediaStreams[0] <> invalid
        setFieldText("video_codec", tr("Video") + ": " + itemData.mediaStreams[0].displayTitle)
    end if
    ' TODO - cmon now. these are buttons, not words
    if itemData.taglines.count() > 0
        setFieldText("tagline", itemData.taglines[0])
    end if

    ' Fill buttons group
    if m.buttons = invalid
        if itemData.mediaSources.Count() > 1
            m.btnCount = 5
        else
            m.btnCount = 4
        end if
        btnWdth = 1440 / m.btnCount - m.buttonGrp.itemSpacings[0]
        m.buttons = []
        ' we dont reference this button anymore
        buttonList = ["Play"]

        if itemData.mediaSources.Count() > 1
            buttonList.push("Version")
        end if
        buttonList.push("Audio")
        buttonList.push("Watched")
        buttonList.push("Favorite")

        m.buttonGrp.buttons = buttonList
        btnIds = { "Play": "play-button", "Version": "video-button", "Audio": "audio-button", "Watched": "watched-button", "Favorite": "favorite-button" }
        for each btn in m.buttonGrp.getChildren(-1, 0)
            btn.id = btnIds[btn.text]
            btn.iconUri = ""
            btn.focusedIconUri = ""
            if btn.text = "Version" then m.videoBtn = btn
            if btn.text = "Audio" then m.audioBtn = btn
            if btn.text = "Favorite" then m.favoriteBtn = btn
            if btn.text = "Watched" then m.watchedBtn = btn
        end for
    end if
    m.buttonGrp.setFocus(true)

    setFavoriteColor()
    setWatchedColor()
    SetUpVideoOptions(itemData.mediaSources)
    SetUpAudioOptions(itemData.mediaStreams)

end sub

sub SetUpVideoOptions(streams)

    videos = []

    for i = 0 to streams.Count() - 1
        if streams[i].VideoType = "VideoFile"
            videos.push({ "Title": streams[i].Name, "Description": tr("Video"), "Selected": m.top.selectedVideoStreamId = streams[i].id, "StreamID": streams[i].id, "video_codec": streams[i].mediaStreams[0].displayTitle })
        end if
    end for

    options = {}
    options.views = videos
    m.videoOptions.options = options

end sub


sub SetUpAudioOptions(streams)

    tracks = []

    for i = 0 to streams.Count() - 1
        if streams[i].Type = "Audio"
            tracks.push({ "Title": streams[i].displayTitle, "Description": streams[i].Title, "Selected": m.top.selectedAudioStreamIndex = i, "StreamIndex": i })
        end if
    end for

    options = {}
    options.views = tracks
    m.audioOptions.options = options

end sub


sub SetDefaultAudioTrack(itemData)
    for i = 0 to itemData.mediaStreams.Count() - 1
        if itemData.mediaStreams[i].Type = "Audio"
            m.top.selectedAudioStreamIndex = i
            setFieldText("audio_codec", tr("Audio") + ": " + itemData.mediaStreams[i].displayTitle)
            exit for
        end if
    end for
end sub

sub setFieldText(field, value)
    node = m.top.findNode(field)
    if node = invalid or value = invalid then return

    ' Handle non strings... Which _shouldn't_ happen, but hey
    if type(value) = "roInt" or type(value) = "Integer"
        value = str(value)
    else if type(value) = "roFloat" or type(value) = "Float"
        value = str(value)
    else if type(value) <> "roString" and type(value) <> "String"
        value = ""
    end if

    node.text = value
end sub

function getRuntime() as integer

    itemData = m.top.itemContent.json

    ' A tick is .1ms, so 1/10,000,000 for ticks to seconds,
    ' then 1/60 for seconds to minutess... 1/600,000,000
    return round(itemData.RunTimeTicks / 600000000.0)
end function

function getEndTime() as string
    itemData = m.top.itemContent.json

    date = CreateObject("roDateTime")
    duration_s = int(itemData.RunTimeTicks / 10000000.0)
    date.fromSeconds(date.asSeconds() + duration_s)
    date.toLocalTime()

    return formatTime(date)
end function

sub setFavoriteColor()
    fave = m.top.itemContent.favorite
    if fave <> invalid and fave
        m.favoriteBtn.textColor = "#00ff00ff"
        m.favoriteBtn.focusedTextColor = "#269926ff"
    else
        m.favoriteBtn.textColor = "0xddddddff"
        m.favoriteBtn.focusedTextColor = "#262626ff"
    end if
end sub

sub setWatchedColor()
    watched = m.top.itemContent.watched
    watched_button = m.watchedBtn
    if watched
        watched_button.textColor = "#ff0000ff"
        watched_button.focusedTextColor = "#992626ff"
    else
        watched_button.textColor = "0xddddddff"
        watched_button.focusedTextColor = "#262626ff"
    end if
end sub

function round(f as float) as integer
    ' BrightScript only has a "floor" round
    ' This compares floor to floor + 1 to find which is closer
    m = int(f)
    n = m + 1
    x = abs(f - m)
    y = abs(f - n)
    if y > x
        return m
    else
        return n
    end if
end function

'
'Check if options updated and any reloading required
sub audioOptionsClosed()
    if m.audioOptions.audioStreamIndex <> m.top.selectedAudioStreamIndex
        m.top.selectedAudioStreamIndex = m.audioOptions.audioStreamIndex
        setFieldText("audio_codec", tr("Audio") + ": " + m.top.itemContent.json.mediaStreams[m.top.selectedAudioStreamIndex].displayTitle)
    end if
    m.buttonGrp.setFocus(true)
end sub

'
' Check if options were updated and if any reloding is needed...
sub videoOptionsClosed()
    if m.videoOptions.videoStreamId <> m.top.selectedVideoStreamId
        m.top.selectedVideoStreamId = m.videoOptions.videoStreamId
        setFieldText("video_codec", tr("Video") + ": " + m.videoOptions.video_codec)
        ' Because the video stream has changed (i.e. the actual video)... we need to reload the audio stream choices for that video
        m.top.unobservefield("itemContent")
        itemData = m.top.itemContent.json
        for each mediaSource in itemData.mediaSources
            if mediaSource.id = m.top.selectedVideoStreamId
                itemData.mediaStreams = []
                for i = 0 to mediaSource.mediaStreams.Count() - 1
                    itemData.mediaStreams.push(mediaSource.mediaStreams[i])
                end for
                SetDefaultAudioTrack(itemData)
                SetUpAudioOptions(itemData.mediaStreams)
                exit for
            end if
        end for
        m.top.itemContent.json = itemData
        m.top.observeField("itemContent", "itemContentChanged")
    end if
    m.buttonGrp.setFocus(true)
end sub

function onKeyEvent(key as string, press as boolean) as boolean

    ' Due to the way the button pressed event works, need to catch the release for the button as the press is being sent
    ' directly to the main loop.  Will get this sorted in the layout update for Movie Details
    if key = "OK"
        if m.videoBtn <> invalid and m.videoBtn.isInFocusChain()
            m.videoOptions.visible = true
            m.videoOptions.setFocus(true)
        else if m.audioBtn <> invalid and m.audioBtn.isInFocusChain()
            m.audioOptions.visible = true
            m.audioOptions.setFocus(true)
        end if
    end if

    if key = "down" and m.buttonGrp.isInFocusChain()
        m.extrasGrid.setFocus(true)
        m.top.findNode("VertSlider").reverse = false
        m.top.findNode("extrasFader").reverse = false
        m.top.findNode("pplAnime").control = "start"
        return true
    end if

    if key = "up" and m.top.findNode("extrasGrid").isInFocusChain()
        if m.extrasGrid.itemFocused = 0
            m.top.findNode("VertSlider").reverse = true
            m.top.findNode("extrasFader").reverse = true
            m.top.findNode("pplAnime").control = "start"
            m.buttonGrp.setFocus(true)
            return true
        end if
    end if

    if not press then return false

    if key = "back"
        if m.audioOptions.visible = true
            m.audioOptions.visible = false
            audioOptionsClosed()
            return true
        else if m.videoOptions.visible = true
            m.videoOptions.visible = false
            videoOptionsClosed()
            return true
        end if
    end if
    return false
end function
