sub init()
    m.top.optionsAvailable = false

    setupAudioNode()
    setupAnimationTasks()
    setupButtons()
    setupInfoNodes()
    setupDataTasks()
    setupScreenSaver()

    m.shuffleEnabled = false
    m.loopMode = ""
    m.buttonCount = m.buttons.getChildCount()
    m.playReported = false

    m.screenSaverTimeout = 300

    m.LoadScreenSaverTimeoutTask.observeField("content", "onScreensaverTimeoutLoaded")
    m.LoadScreenSaverTimeoutTask.control = "RUN"

    m.di = CreateObject("roDeviceInfo")

    ' Write screen tracker for screensaver
    WriteAsciiFile("tmp:/scene.temp", "nowplaying")
    MoveFile("tmp:/scene.temp", "tmp:/scene")

    loadButtons()
    pageContentChanged()
end sub

sub onScreensaverTimeoutLoaded()
    data = m.LoadScreenSaverTimeoutTask.content
    m.LoadScreenSaverTimeoutTask.unobserveField("content")
    if isValid(data)
        m.screenSaverTimeout = data
    end if
end sub

sub setupScreenSaver()
    m.screenSaverBackground = m.top.FindNode("screenSaverBackground")

    ' Album Art Screensaver
    m.screenSaverAlbumCover = m.top.FindNode("screenSaverAlbumCover")
    m.screenSaverAlbumAnimation = m.top.findNode("screenSaverAlbumAnimation")
    m.screenSaverAlbumCoverFadeIn = m.top.findNode("screenSaverAlbumCoverFadeIn")

    ' Jellyfin Screensaver
    m.PosterOne = m.top.findNode("PosterOne")
    m.PosterOne.uri = "pkg:/images/logo.png"
    m.BounceAnimation = m.top.findNode("BounceAnimation")
    m.PosterOneFadeIn = m.top.findNode("PosterOneFadeIn")
end sub

sub setupAnimationTasks()
    m.displayButtonsAnimation = m.top.FindNode("displayButtonsAnimation")
    m.playPositionAnimation = m.top.FindNode("playPositionAnimation")
    m.playPositionAnimationWidth = m.top.FindNode("playPositionAnimationWidth")

    m.bufferPositionAnimation = m.top.FindNode("bufferPositionAnimation")
    m.bufferPositionAnimationWidth = m.top.FindNode("bufferPositionAnimationWidth")

    m.screenSaverStartAnimation = m.top.FindNode("screenSaverStartAnimation")
end sub

' Creates tasks to gather data needed to render Scene and play song
sub setupDataTasks()
    ' Load meta data
    m.LoadMetaDataTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadMetaDataTask.itemsToLoad = "metaData"

    ' Load background image
    m.LoadBackdropImageTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadBackdropImageTask.itemsToLoad = "backdropImage"

    ' Load audio stream
    m.LoadAudioStreamTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadAudioStreamTask.itemsToLoad = "audioStream"

    m.LoadScreenSaverTimeoutTask = CreateObject("roSGNode", "LoadScreenSaverTimeoutTask")
end sub

' Creates audio node used to play song(s)
sub setupAudioNode()
    m.top.audio = createObject("RoSGNode", "Audio")
    m.top.audio.observeField("state", "audioStateChanged")
    m.top.audio.observeField("position", "audioPositionChanged")
    m.top.audio.observeField("bufferingStatus", "bufferPositionChanged")
end sub

' Setup playback buttons, default to Play button selected
sub setupButtons()
    m.buttons = m.top.findNode("buttons")
    m.top.observeField("selectedButtonIndex", "onButtonSelectedChange")
    m.previouslySelectedButtonIndex = 1
    m.top.selectedButtonIndex = 2
end sub

' Event handler when user selected a different playback button
sub onButtonSelectedChange()
    ' Change previously selected button back to default image
    selectedButton = m.buttons.getChild(m.previouslySelectedButtonIndex)
    selectedButton.uri = selectedButton.uri.Replace("-selected", "-default")

    ' Change selected button image to selected image
    selectedButton = m.buttons.getChild(m.top.selectedButtonIndex)
    selectedButton.uri = selectedButton.uri.Replace("-default", "-selected")
end sub

sub setupInfoNodes()
    m.albumCover = m.top.findNode("albumCover")
    m.backDrop = m.top.findNode("backdrop")
    m.playPosition = m.top.findNode("playPosition")
    m.bufferPosition = m.top.findNode("bufferPosition")
    m.seekBar = m.top.findNode("seekBar")
    m.numberofsongsField = m.top.findNode("numberofsongs")
    m.shuffleIndicator = m.top.findNode("shuffleIndicator")
    m.loopIndicator = m.top.findNode("loopIndicator")
end sub

sub bufferPositionChanged()
    if not isValid(m.top.audio.bufferingStatus)
        bufferPositionBarWidth = m.seekBar.width
    else
        bufferPositionBarWidth = m.seekBar.width * m.top.audio.bufferingStatus.percentage
    end if

    ' Ensure position bar is never wider than the seek bar
    if bufferPositionBarWidth > m.seekBar.width
        bufferPositionBarWidth = m.seekBar.width
    end if

    ' Use animation to make the display smooth
    m.bufferPositionAnimationWidth.keyValue = [m.bufferPosition.width, bufferPositionBarWidth]
    m.bufferPositionAnimation.control = "start"
end sub

sub audioPositionChanged()
    if m.top.audio.position = 0
        m.playPosition.width = 0
    end if

    if not isValid(m.top.audio.position)
        playPositionBarWidth = 0
    else if not isValid(m.songDuration)
        playPositionBarWidth = 0
    else
        songPercentComplete = m.top.audio.position / m.songDuration
        playPositionBarWidth = m.seekBar.width * songPercentComplete
    end if

    ' Ensure position bar is never wider than the seek bar
    if playPositionBarWidth > m.seekBar.width
        playPositionBarWidth = m.seekBar.width
    end if

    ' Use animation to make the display smooth
    m.playPositionAnimationWidth.keyValue = [m.playPosition.width, playPositionBarWidth]
    m.playPositionAnimation.control = "start"

    ' Only fall into screensaver logic if the user has screensaver enabled in Roku settings
    if m.screenSaverTimeout > 0
        if m.di.TimeSinceLastKeypress() >= m.screenSaverTimeout - 2
            if not screenSaverActive()
                startScreenSaver()
            end if
        end if
    end if
end sub

function screenSaverActive() as boolean
    return m.screenSaverBackground.visible or m.screenSaverAlbumCover.opacity > 0 or m.PosterOne.opacity > 0
end function

sub startScreenSaver()
    m.screenSaverBackground.visible = true
    m.top.overhangVisible = false

    if m.albumCover.uri = ""
        ' Jellyfin Logo Screensaver
        m.PosterOne.visible = true
        m.PosterOneFadeIn.control = "start"
        m.BounceAnimation.control = "start"
    else
        ' Album Art Screensaver
        m.screenSaverAlbumCoverFadeIn.control = "start"
        m.screenSaverAlbumAnimation.control = "start"
    end if
end sub

sub endScreenSaver()
    m.PosterOneFadeIn.control = "pause"
    m.screenSaverAlbumCoverFadeIn.control = "pause"
    m.screenSaverAlbumAnimation.control = "pause"
    m.BounceAnimation.control = "pause"
    m.screenSaverBackground.visible = false
    m.screenSaverAlbumCover.opacity = 0
    m.PosterOne.opacity = 0
    m.top.overhangVisible = true
end sub

sub audioStateChanged()

    if m.top.audio.state = "playing"
        if m.playReported
            ReportPlayback()
        else
            ReportPlayback("start")
            m.playReported = true
        end if
    else if m.top.audio.state = "paused"
        ReportPlayback()
    else if m.top.audio.state = "stopped"
        ReportPlayback("stop")
        m.playReported = false
    else if m.top.audio.state = "finished"
        ReportPlayback("stop")
        m.playReported = false
    end if

    ' Song Finished, attempt to move to next song
    if m.top.audio.state = "finished"
        ' User has enabled single song loop, play current song again
        if m.loopMode = "one"
            playAction()
            return
        end if

        if m.global.queueManager.callFunc("getPosition") < m.global.queueManager.callFunc("getCount") - 1
            ' We are not at the end of the song queue, advance to next song
            LoadNextSong()
        else
            ' We are at the end of the song queue

            ' User has enabled loop for entire song queue, move back to first song
            if m.loopMode = "all"
                m.global.queueManager.callFunc("setPosition", -1)
                LoadNextSong()
                return
            end if

            ' Return to previous screen
            m.top.state = "finished"
        end if
    end if
end sub

function playAction() as boolean
    if m.top.audio.state = "playing"
        m.top.audio.control = "pause"
        ' Allow screen to go to real screensaver
        WriteAsciiFile("tmp:/scene.temp", "nowplaying-paused")
        MoveFile("tmp:/scene.temp", "tmp:/scene")
    else if m.top.audio.state = "paused"
        m.top.audio.control = "resume"
        ' Write screen tracker for screensaver
        WriteAsciiFile("tmp:/scene.temp", "nowplaying")
        MoveFile("tmp:/scene.temp", "tmp:/scene")
    else if m.top.audio.state = "finished"
        m.top.audio.control = "play"
        ' Write screen tracker for screensaver
        WriteAsciiFile("tmp:/scene.temp", "nowplaying")
        MoveFile("tmp:/scene.temp", "tmp:/scene")
    end if

    return true
end function

function previousClicked() as boolean
    if m.top.audio.state = "playing"
        m.top.audio.control = "stop"
    end if

    if m.global.queueManager.callFunc("getPosition") > 0
        m.global.queueManager.callFunc("moveBack")
        pageContentChanged()
    end if

    return true
end function

function loopClicked() as boolean

    if m.loopMode = ""
        m.loopIndicator.opacity = "1"
        m.loopIndicator.uri = m.loopIndicator.uri.Replace("-off", "-on")
        m.loopMode = "all"
    else if m.loopMode = "all"
        m.loopIndicator.uri = m.loopIndicator.uri.Replace("-on", "1-on")
        m.loopMode = "one"
    else
        m.loopIndicator.uri = m.loopIndicator.uri.Replace("1-on", "-off")
        m.loopMode = ""
    end if

    return true
end function

function nextClicked() as boolean
    if m.global.queueManager.callFunc("getPosition") < m.global.queueManager.callFunc("getCount") - 1
        LoadNextSong()
    end if

    return true
end function

sub toggleShuffleEnabled()
    m.shuffleEnabled = not m.shuffleEnabled
end sub

function findCurrentSongIndex(songList) as integer
    for i = 0 to songList.count() - 1
        if songList[i].id = m.global.queueManager.callFunc("getCurrentItem").id
            return i
        end if
    end for

    return 0
end function

function shuffleClicked() as boolean

    toggleShuffleEnabled()

    if not m.shuffleEnabled
        m.shuffleIndicator.opacity = ".4"
        m.shuffleIndicator.uri = m.shuffleIndicator.uri.Replace("-on", "-off")

        currentSongIndex = findCurrentSongIndex(m.originalSongList)
        m.global.queueManager.callFunc("set", m.originalSongList)
        m.global.queueManager.callFunc("setPosition", currentSongIndex)
        setFieldTextValue("numberofsongs", "Track " + stri(m.global.queueManager.callFunc("getPosition") + 1) + "/" + stri(m.global.queueManager.callFunc("getCount")))

        return true
    end if

    m.shuffleIndicator.opacity = "1"
    m.shuffleIndicator.uri = m.shuffleIndicator.uri.Replace("-off", "-on")

    m.originalSongList = m.global.queueManager.callFunc("getQueue")

    songIDArray = m.global.queueManager.callFunc("getQueue")

    ' Move the currently playing song to the front of the queue
    temp = m.global.queueManager.callFunc("top")
    songIDArray[0] = m.global.queueManager.callFunc("getCurrentItem")
    songIDArray[m.global.queueManager.callFunc("getPosition")] = temp

    for i = 1 to songIDArray.count() - 1
        j = Rnd(songIDArray.count() - 1)
        temp = songIDArray[i]
        songIDArray[i] = songIDArray[j]
        songIDArray[j] = temp
    end for

    m.global.queueManager.callFunc("set", songIDArray)

    return true
end function

sub LoadNextSong()
    if m.top.audio.state = "playing"
        m.top.audio.control = "stop"
    end if

    ' Reset playPosition bar without animation
    m.playPosition.width = 0
    m.global.queueManager.callFunc("moveForward")
    pageContentChanged()
end sub

' Update values on screen when page content changes
sub pageContentChanged()

    ' Reset buffer bar without animation
    m.bufferPosition.width = 0

    useMetaTask = false
    currentItem = m.global.queueManager.callFunc("getCurrentItem")

    if not isValid(currentItem.RunTimeTicks)
        useMetaTask = true
    end if

    if not isValid(currentItem.AlbumArtist)
        useMetaTask = true
    end if

    if not isValid(currentItem.name)
        useMetaTask = true
    end if

    if not isValid(currentItem.Artists)
        useMetaTask = true
    end if

    if useMetaTask
        m.LoadMetaDataTask.itemId = currentItem.id
        m.LoadMetaDataTask.observeField("content", "onMetaDataLoaded")
        m.LoadMetaDataTask.control = "RUN"
    else
        if isValid(currentItem.ParentBackdropItemId)
            setBackdropImage(ImageURL(currentItem.ParentBackdropItemId, "Backdrop", { "maxHeight": "720", "maxWidth": "1280" }))
        end if

        setPosterImage(ImageURL(currentItem.id, "Primary", { "maxHeight": 500, "maxWidth": 500 }))
        setScreenTitle(currentItem)
        setOnScreenTextValues(currentItem)
        m.songDuration = currentItem.RunTimeTicks / 10000000.0
    end if

    m.LoadAudioStreamTask.itemId = currentItem.id
    m.LoadAudioStreamTask.observeField("content", "onAudioStreamLoaded")
    m.LoadAudioStreamTask.control = "RUN"
end sub

' If we have more and 1 song to play, fade in the next and previous controls
sub loadButtons()
    if m.global.queueManager.callFunc("getCount") > 1
        m.shuffleIndicator.opacity = ".4"
        m.loopIndicator.opacity = ".4"
        m.displayButtonsAnimation.control = "start"
    end if
end sub

sub onAudioStreamLoaded()
    data = m.LoadAudioStreamTask.content[0]
    m.LoadAudioStreamTask.unobserveField("content")
    if data <> invalid and data.count() > 0
        m.top.audio.content = data
        m.top.audio.control = "none"
        m.top.audio.control = "play"
    end if
end sub

sub onBackdropImageLoaded()
    data = m.LoadBackdropImageTask.content[0]
    m.LoadBackdropImageTask.unobserveField("content")
    if isValid(data) and data <> ""
        setBackdropImage(data)
    end if
end sub

sub onMetaDataLoaded()
    data = m.LoadMetaDataTask.content[0]
    m.LoadMetaDataTask.unobserveField("content")
    if data <> invalid and data.count() > 0

        ' Use metadata to load backdrop image
        if isValid(data.json)
            if isValid(data.json.ArtistItems)
                if data.json.ArtistItems.count() > 0
                    if isValid(data.json.ArtistItems[0].id)
                        m.LoadBackdropImageTask.itemId = data.json.ArtistItems[0].id
                        m.LoadBackdropImageTask.observeField("content", "onBackdropImageLoaded")
                        m.LoadBackdropImageTask.control = "RUN"
                    end if
                end if
            end if
        end if

        setPosterImage(data.posterURL)
        setScreenTitle(data.json)
        setOnScreenTextValues(data.json)

        m.songDuration = data.json.RunTimeTicks / 10000000.0
    end if
end sub

' Set poster image on screen
sub setPosterImage(posterURL)
    if isValid(posterURL)
        if m.albumCover.uri <> posterURL
            m.albumCover.uri = posterURL
            m.screenSaverAlbumCover.uri = posterURL
        end if
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

    if m.top.overhangTitle <> newTitle
        m.top.overhangTitle = newTitle
    end if
end sub

' Populate on screen text variables
sub setOnScreenTextValues(json)
    if isValid(json)
        currentSongIndex = m.global.queueManager.callFunc("getPosition")

        if m.shuffleEnabled
            currentSongIndex = findCurrentSongIndex(m.originalSongList)
        end if
        setFieldTextValue("numberofsongs", "Track " + stri(currentSongIndex + 1) + "/" + stri(m.global.queueManager.callFunc("getCount")))
        setFieldTextValue("artist", json.Artists[0])
        setFieldTextValue("song", json.name)
    end if
end sub

' Add backdrop image to screen
sub setBackdropImage(data)
    if isValid(data)
        if m.backDrop.uri <> data
            m.backDrop.uri = data
        end if
    end if
end sub

' Process key press events
function onKeyEvent(key as string, press as boolean) as boolean

    ' Key bindings for remote control buttons
    if press
        ' If user presses key to turn off screensaver, don't do anything else with it
        if screenSaverActive()
            endScreenSaver()
            return true
        end if

        if key = "play"
            return playAction()
        else if key = "back"
            m.top.audio.control = "stop"
        else if key = "rewind"
            return previousClicked()
        else if key = "fastforward"
            return nextClicked()
        else if key = "left"
            if m.global.queueManager.callFunc("getCount") = 1 then return false

            if m.top.selectedButtonIndex > 0
                m.previouslySelectedButtonIndex = m.top.selectedButtonIndex
                m.top.selectedButtonIndex = m.top.selectedButtonIndex - 1
            end if
            return true
        else if key = "right"
            if m.global.queueManager.callFunc("getCount") = 1 then return false

            m.previouslySelectedButtonIndex = m.top.selectedButtonIndex
            if m.top.selectedButtonIndex < m.buttonCount - 1 then m.top.selectedButtonIndex = m.top.selectedButtonIndex + 1
            return true
        else if key = "OK"
            if m.buttons.getChild(m.top.selectedButtonIndex).id = "play"
                return playAction()
            else if m.buttons.getChild(m.top.selectedButtonIndex).id = "previous"
                return previousClicked()
            else if m.buttons.getChild(m.top.selectedButtonIndex).id = "next"
                return nextClicked()
            else if m.buttons.getChild(m.top.selectedButtonIndex).id = "shuffle"
                return shuffleClicked()
            else if m.buttons.getChild(m.top.selectedButtonIndex).id = "loop"
                return loopClicked()
            end if
        end if
    end if

    return false
end function

sub OnScreenHidden()
    ' Write screen tracker for screensaver
    WriteAsciiFile("tmp:/scene.temp", "")
    MoveFile("tmp:/scene.temp", "tmp:/scene")
end sub

' Report playback to server
sub ReportPlayback(state = "update" as string)

    if m.top.audio.position = invalid then return

    params = {
        "ItemId": m.global.queueManager.callFunc("getCurrentItem").id,
        "PlaySessionId": m.top.audio.content.id,
        "PositionTicks": int(m.top.audio.position) * 10000000&, 'Ensure a LongInteger is used
        "IsPaused": (m.top.audio.state = "paused")
    }

    ' Report playstate via worker task
    playstateTask = m.global.playstateTask
    playstateTask.setFields({ status: state, params: params })
    playstateTask.control = "RUN"
end sub
