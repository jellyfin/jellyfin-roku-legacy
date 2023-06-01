sub Main (args as dynamic) as void
    ' The main function that runs when the application is launched.
    m.screen = CreateObject("roSGScreen")
    ' Set global constants
    setConstants()
    ' Write screen tracker for screensaver
    WriteAsciiFile("tmp:/scene.temp", "")
    MoveFile("tmp:/scene.temp", "tmp:/scene")

    m.port = CreateObject("roMessagePort")
    m.screen.setMessagePort(m.port)
    ' Set any initial Global Variables
    m.global = m.screen.getGlobalNode()
    SaveAppToGlobal()
    SaveDeviceToGlobal()
    session.Init()

    m.scene = m.screen.CreateScene("JFScene")
    m.screen.show() ' vscode_rale_tracker_entry

    playstateTask = CreateObject("roSGNode", "PlaystateTask")
    playstateTask.id = "playstateTask"

    sceneManager = CreateObject("roSGNode", "SceneManager")
    sceneManager.observeField("dataReturned", m.port)

    m.global.addFields({ app_loaded: false, playstateTask: playstateTask, sceneManager: sceneManager })
    m.global.addFields({ queueManager: CreateObject("roSGNode", "QueueManager") })
    m.global.addFields({ audioPlayer: CreateObject("roSGNode", "AudioPlayer") })

    app_start:
    ' First thing to do is validate the ability to use the API
    if not LoginFlow() then return
    ' tell jellyfin server about device capabilities
    PostDeviceProfile()
    ' remove previous scenes from the stack
    sceneManager.callFunc("clearScenes")

    ' load home page
    sceneManager.currentUser = m.global.session.user.name
    group = CreateHomeGroup()
    group.callFunc("loadLibraries")
    sceneManager.callFunc("pushScene", group)

    m.scene.observeField("exit", m.port)

    ' Downloads and stores a fallback font to tmp:/
    configEncoding = api.system.GetConfigurationByName("encoding")

    if isValid(configEncoding) and isValid(configEncoding.EnableFallbackFont)
        if configEncoding.EnableFallbackFont
            re = CreateObject("roRegex", "Name.:.(.*?).,.Size", "s")
            filename = APIRequest("FallbackFont/Fonts").GetToString()
            if isValid(filename)
                filename = re.match(filename)
                if isValid(filename) and filename.count() > 0
                    filename = filename[1]
                    APIRequest("FallbackFont/Fonts/" + filename).gettofile("tmp:/font")
                end if
            end if
        end if
    end if

    ' Only show the Whats New popup the first time a user runs a new client version.
    if m.global.app.version <> get_setting("LastRunVersion")
        ' Ensure the user hasn't disabled Whats New popups
        if m.global.session.user.settings["load.allowwhatsnew"] = true
            set_setting("LastRunVersion", m.global.app.version)
            dialog = createObject("roSGNode", "WhatsNewDialog")
            m.scene.dialog = dialog
            m.scene.dialog.observeField("buttonSelected", m.port)
        end if
    end if

    ' Handle input messages
    input = CreateObject("roInput")
    input.SetMessagePort(m.port)

    device = CreateObject("roDeviceInfo")
    device.setMessagePort(m.port)
    device.EnableScreensaverExitedEvent(true)
    device.EnableAppFocusEvent(true)
    device.EnableLowGeneralMemoryEvent(true)
    device.EnableLinkStatusEvent(true)
    device.EnableCodecCapChangedEvent(true)
    device.EnableAudioGuideChangedEvent(true)

    ' Check if we were sent content to play with the startup command (Deep Link)
    if isValidAndNotEmpty(args.mediaType) and isValidAndNotEmpty(args.contentId)

        deepLinkVideo = {
            id: args.contentId,
            type: "video"
        }

        m.global.queueManager.callFunc("push", deepLinkVideo)
        m.global.queueManager.callFunc("playQueue")
    end if

    ' This is the core logic loop. Mostly for transitioning between scenes
    ' This now only references m. fields so could be placed anywhere, in theory
    ' "group" is always "whats on the screen"
    ' m.scene's children is the "previous view" stack
    while true
        msg = wait(0, m.port)
        if type(msg) = "roSGScreenEvent" and msg.isScreenClosed()
            print "CLOSING SCREEN"
            return
        else if isNodeEvent(msg, "exit")
            return
        else if isNodeEvent(msg, "closeSidePanel")
            group = sceneManager.callFunc("getActiveScene")
            if group.lastFocus <> invalid
                group.lastFocus.setFocus(true)
            else
                group.setFocus(true)
            end if
        else if isNodeEvent(msg, "quickPlayNode")
            group = sceneManager.callFunc("getActiveScene")
            reportingNode = msg.getRoSGNode()
            itemNode = reportingNode.quickPlayNode
            if isValid(itemNode) and isValid(itemNode.id) and itemNode.id <> ""
                if itemNode.type = "Episode" or itemNode.type = "Movie" or itemNode.type = "Video"
                    audio_stream_idx = 0
                    if isValid(itemNode.selectedAudioStreamIndex) and itemNode.selectedAudioStreamIndex > 0
                        audio_stream_idx = itemNode.selectedAudioStreamIndex
                    end if

                    itemNode.selectedAudioStreamIndex = audio_stream_idx

                    playbackPosition = 0

                    ' Display playback options dialog
                    if isValid(itemNode.json) and isValid(itemNode.json.userdata) and isValid(itemNode.json.userdata.PlaybackPositionTicks)
                        playbackPosition = itemNode.json.userdata.PlaybackPositionTicks
                    end if

                    if playbackPosition > 0
                        m.global.queueManager.callFunc("hold", itemNode)
                        playbackOptionDialog(playbackPosition, itemNode.json)
                    else
                        m.global.queueManager.callFunc("clear")
                        m.global.queueManager.callFunc("push", itemNode)
                        m.global.queueManager.callFunc("playQueue")
                    end if

                    ' Prevent quick play node from double firing
                    reportingNode.quickPlayNode = invalid

                    if LCase(group.subtype()) = "tvepisodes"
                        if isValid(group.lastFocus)
                            group.lastFocus.setFocus(true)
                        end if
                    end if
                end if
            end if
        else if isNodeEvent(msg, "selectedItem")
            ' If you select a library from ANYWHERE, follow this flow
            selectedItem = msg.getData()
            if isValid(selectedItem)
                selectedItemType = selectedItem.type


                if selectedItemType = "CollectionFolder"
                    if selectedItem.collectionType = "movies"
                        group = CreateMovieLibraryView(selectedItem)
                    else if selectedItem.collectionType = "music"
                        group = CreateMusicLibraryView(selectedItem)
                    else
                        group = CreateItemGrid(selectedItem)
                    end if
                    sceneManager.callFunc("pushScene", group)
                else if selectedItemType = "Folder" and selectedItem.json.type = "Genre"
                    ' User clicked on a genre folder
                    if selectedItem.json.MovieCount > 0
                        group = CreateMovieLibraryView(selectedItem)
                    else
                        group = CreateItemGrid(selectedItem)
                    end if
                    sceneManager.callFunc("pushScene", group)
                else if selectedItemType = "Folder" and selectedItem.json.type = "MusicGenre"
                    group = CreateMusicLibraryView(selectedItem)
                    sceneManager.callFunc("pushScene", group)
                else if selectedItemType = "UserView" or selectedItemType = "Folder" or selectedItemType = "Channel" or selectedItemType = "Boxset"
                    group = CreateItemGrid(selectedItem)
                    sceneManager.callFunc("pushScene", group)
                else if selectedItemType = "Episode"
                    ' User has selected a TV episode they want us to play
                    audio_stream_idx = 0
                    if isValid(selectedItem.selectedAudioStreamIndex) and selectedItem.selectedAudioStreamIndex > 0
                        audio_stream_idx = selectedItem.selectedAudioStreamIndex
                    end if

                    selectedItem.selectedAudioStreamIndex = audio_stream_idx

                    ' If we are playing a playlist, always start at the beginning
                    if m.global.queueManager.callFunc("getCount") > 1
                        selectedItem.startingPoint = 0
                        m.global.queueManager.callFunc("clear")
                        m.global.queueManager.callFunc("push", selectedItem)
                        m.global.queueManager.callFunc("playQueue")
                    else
                        ' Display playback options dialog
                        if selectedItem.json.userdata.PlaybackPositionTicks > 0
                            m.global.queueManager.callFunc("hold", selectedItem)
                            playbackOptionDialog(selectedItem.json.userdata.PlaybackPositionTicks, selectedItem.json)
                        else
                            m.global.queueManager.callFunc("clear")
                            m.global.queueManager.callFunc("push", selectedItem)
                            m.global.queueManager.callFunc("playQueue")
                        end if
                    end if


                else if selectedItemType = "Series"
                    group = CreateSeriesDetailsGroup(selectedItem.json.id)
                else if selectedItemType = "Season"
                    group = CreateSeasonDetailsGroupByID(selectedItem.json.SeriesId, selectedItem.id)
                else if selectedItemType = "Movie"
                    ' open movie detail page
                    group = CreateMovieDetailsGroup(selectedItem)
                else if selectedItemType = "Person"
                    CreatePersonView(selectedItem)
                else if selectedItemType = "TvChannel" or selectedItemType = "Video" or selectedItemType = "Program"
                    ' User selected a Live TV channel / program

                    ' Show Channel Loading spinner
                    dialog = createObject("roSGNode", "ProgressDialog")
                    dialog.title = tr("Loading Channel Data")
                    m.scene.dialog = dialog

                    ' User selected a program. Play the channel the program is on
                    if LCase(selectedItemType) = "program"
                        selectedItem.id = selectedItem.json.ChannelId
                    end if

                    ' Display playback options dialog
                    if selectedItem.json.userdata.PlaybackPositionTicks > 0
                        dialog.close = true
                        m.global.queueManager.callFunc("hold", selectedItem)
                        playbackOptionDialog(selectedItem.json.userdata.PlaybackPositionTicks, selectedItem.json)
                    else
                        m.global.queueManager.callFunc("clear")
                        m.global.queueManager.callFunc("push", selectedItem)
                        m.global.queueManager.callFunc("playQueue")
                        dialog.close = true
                    end if

                else if selectedItemType = "Photo"
                    ' Nothing to do here, handled in ItemGrid
                else if selectedItemType = "MusicArtist"
                    group = CreateArtistView(selectedItem.json)
                    if not isValid(group)
                        message_dialog(tr("Unable to find any albums or songs belonging to this artist"))
                    end if
                else if selectedItemType = "MusicAlbum"
                    group = CreateAlbumView(selectedItem.json)
                else if selectedItemType = "Playlist"
                    group = CreatePlaylistView(selectedItem.json)
                else if selectedItemType = "Audio"
                    m.global.queueManager.callFunc("clear")
                    m.global.queueManager.callFunc("resetShuffle")
                    m.global.queueManager.callFunc("push", selectedItem.json)
                    m.global.queueManager.callFunc("playQueue")
                else
                    ' TODO - switch on more node types
                    message_dialog("This type is not yet supported: " + selectedItemType + ".")
                end if
            end if
        else if isNodeEvent(msg, "movieSelected")
            ' If you select a movie from ANYWHERE, follow this flow
            node = getMsgPicker(msg, "picker")
            group = CreateMovieDetailsGroup(node)
        else if isNodeEvent(msg, "seriesSelected")
            ' If you select a TV Series from ANYWHERE, follow this flow
            node = getMsgPicker(msg, "picker")
            group = CreateSeriesDetailsGroup(node.id)
        else if isNodeEvent(msg, "seasonSelected")
            ' If you select a TV Season from ANYWHERE, follow this flow
            ptr = msg.getData()
            ' ptr is for [row, col] of selected item... but we only have 1 row
            series = msg.getRoSGNode()
            if isValid(ptr) and ptr.count() >= 2 and isValid(ptr[1]) and isValid(series) and isValid(series.seasonData) and isValid(series.seasonData.items)
                node = series.seasonData.items[ptr[1]]
                group = CreateSeasonDetailsGroup(series.itemContent, node)
            end if
        else if isNodeEvent(msg, "musicAlbumSelected")
            ' If you select a Music Album from ANYWHERE, follow this flow
            ptr = msg.getData()
            albums = msg.getRoSGNode()
            node = albums.musicArtistAlbumData.items[ptr]
            group = CreateAlbumView(node)
        else if isNodeEvent(msg, "appearsOnSelected")
            ' If you select a Music Album from ANYWHERE, follow this flow
            ptr = msg.getData()
            albums = msg.getRoSGNode()
            node = albums.musicArtistAppearsOnData.items[ptr]
            group = CreateAlbumView(node)
        else if isNodeEvent(msg, "playSong")
            ' User has selected audio they want us to play
            selectedIndex = msg.getData()
            screenContent = msg.getRoSGNode()

            m.global.queueManager.callFunc("clear")
            m.global.queueManager.callFunc("resetShuffle")
            m.global.queueManager.callFunc("push", screenContent.albumData.items[selectedIndex])
            m.global.queueManager.callFunc("playQueue")
        else if isNodeEvent(msg, "playItem")
            ' User has selected audio they want us to play
            selectedIndex = msg.getData()
            screenContent = msg.getRoSGNode()

            m.global.queueManager.callFunc("clear")
            m.global.queueManager.callFunc("resetShuffle")
            m.global.queueManager.callFunc("push", screenContent.albumData.items[selectedIndex])
            m.global.queueManager.callFunc("playQueue")
        else if isNodeEvent(msg, "playAllSelected")
            ' User has selected playlist of of audio they want us to play
            screenContent = msg.getRoSGNode()
            m.spinner = screenContent.findNode("spinner")
            m.spinner.visible = true

            m.global.queueManager.callFunc("clear")
            m.global.queueManager.callFunc("resetShuffle")
            m.global.queueManager.callFunc("set", screenContent.albumData.items)
            m.global.queueManager.callFunc("playQueue")
        else if isNodeEvent(msg, "playArtistSelected")
            ' User has selected playlist of of audio they want us to play
            screenContent = msg.getRoSGNode()

            m.global.queueManager.callFunc("clear")
            m.global.queueManager.callFunc("resetShuffle")
            m.global.queueManager.callFunc("set", CreateArtistMix(screenContent.pageContent.id).Items)
            m.global.queueManager.callFunc("playQueue")

        else if isNodeEvent(msg, "instantMixSelected")
            ' User has selected instant mix
            ' User has selected playlist of of audio they want us to play
            screenContent = msg.getRoSGNode()
            m.spinner = screenContent.findNode("spinner")
            if isValid(m.spinner)
                m.spinner.visible = true
            end if

            viewHandled = false

            ' Create instant mix based on selected album
            if isValid(screenContent.albumData)
                if isValid(screenContent.albumData.items)
                    if screenContent.albumData.items.count() > 0
                        m.global.queueManager.callFunc("clear")
                        m.global.queueManager.callFunc("resetShuffle")
                        m.global.queueManager.callFunc("set", CreateInstantMix(screenContent.albumData.items[0].id).Items)
                        m.global.queueManager.callFunc("playQueue")

                        viewHandled = true
                    end if
                end if
            end if

            if not viewHandled
                ' Create instant mix based on selected artist
                m.global.queueManager.callFunc("clear")
                m.global.queueManager.callFunc("resetShuffle")
                m.global.queueManager.callFunc("set", CreateInstantMix(screenContent.pageContent.id).Items)
                m.global.queueManager.callFunc("playQueue")
            end if

        else if isNodeEvent(msg, "search_value")
            query = msg.getRoSGNode().search_value
            group.findNode("SearchBox").visible = false
            options = group.findNode("SearchSelect")
            options.visible = true
            options.setFocus(true)

            dialog = createObject("roSGNode", "ProgressDialog")
            dialog.title = tr("Loading Search Data")
            m.scene.dialog = dialog
            results = SearchMedia(query)
            dialog.close = true
            options.itemData = results
            options.query = query
        else if isNodeEvent(msg, "itemSelected")
            ' Search item selected
            node = getMsgPicker(msg)
            ' TODO - swap this based on target.mediatype
            ' types: [ Series (Show), Episode, Movie, Audio, Person, Studio, MusicArtist ]
            if node.type = "Series"
                group = CreateSeriesDetailsGroup(node.id)
            else if node.type = "Movie"
                group = CreateMovieDetailsGroup(node)
            else if node.type = "MusicArtist"
                group = CreateArtistView(node.json)
            else if node.type = "MusicAlbum"
                group = CreateAlbumView(node.json)
            else if node.type = "Audio"
                m.global.queueManager.callFunc("clear")
                m.global.queueManager.callFunc("resetShuffle")
                m.global.queueManager.callFunc("push", node.json)
                m.global.queueManager.callFunc("playQueue")
            else if node.type = "Person"
                group = CreatePersonView(node)
            else if node.type = "TvChannel"
                group = CreateVideoPlayerGroup(node.id)
                sceneManager.callFunc("pushScene", group)
            else if node.type = "Episode"
                group = CreateVideoPlayerGroup(node.id)
                sceneManager.callFunc("pushScene", group)
            else if node.type = "Audio"
                selectedIndex = msg.getData()
                screenContent = msg.getRoSGNode()
                m.global.queueManager.callFunc("clear")
                m.global.queueManager.callFunc("resetShuffle")
                m.global.queueManager.callFunc("push", screenContent.albumData.items[node.id])
                m.global.queueManager.callFunc("playQueue")
            else
                ' TODO - switch on more node types
                message_dialog("This type is not yet supported: " + node.type + ".")
            end if
        else if isNodeEvent(msg, "buttonSelected")
            ' If a button is selected, we have some determining to do
            btn = getButton(msg)
            group = sceneManager.callFunc("getActiveScene")
            if isValid(btn) and btn.id = "play-button"
                ' User chose Play button from movie detail view

                ' Check if a specific Audio Stream was selected
                audio_stream_idx = 0
                if isValid(group) and isValid(group.selectedAudioStreamIndex)
                    audio_stream_idx = group.selectedAudioStreamIndex
                end if

                group.itemContent.selectedAudioStreamIndex = audio_stream_idx
                group.itemContent.id = group.selectedVideoStreamId

                ' Display playback options dialog
                if group.itemContent.json.userdata.PlaybackPositionTicks > 0
                    m.global.queueManager.callFunc("hold", group.itemContent)
                    playbackOptionDialog(group.itemContent.json.userdata.PlaybackPositionTicks, group.itemContent.json)
                else
                    m.global.queueManager.callFunc("clear")
                    m.global.queueManager.callFunc("push", group.itemContent)
                    m.global.queueManager.callFunc("playQueue")
                end if

                if isValid(group) and isValid(group.lastFocus) and isValid(group.lastFocus.id) and group.lastFocus.id = "main_group"
                    buttons = group.findNode("buttons")
                    if isValid(buttons)
                        group.lastFocus = group.findNode("buttons")
                    end if
                end if

                if isValid(group) and isValid(group.lastFocus)
                    group.lastFocus.setFocus(true)
                end if

            else if btn <> invalid and btn.id = "trailer-button"
                ' User chose to play a trailer from the movie detail view
                dialog = createObject("roSGNode", "ProgressDialog")
                dialog.title = tr("Loading trailer")
                m.scene.dialog = dialog

                trailerData = api.users.GetLocalTrailers(m.global.session.user.id, group.id)

                if isValid(trailerData) and isValid(trailerData[0]) and isValid(trailerData[0].id)
                    m.global.queueManager.callFunc("clear")
                    m.global.queueManager.callFunc("set", trailerData)
                    m.global.queueManager.callFunc("playQueue")
                    dialog.close = true
                end if

                if isValid(group) and isValid(group.lastFocus)
                    group.lastFocus.setFocus(true)
                end if
            else if btn <> invalid and btn.id = "watched-button"
                movie = group.itemContent
                if isValid(movie) and isValid(movie.watched) and isValid(movie.id)
                    if movie.watched
                        UnmarkItemWatched(movie.id)
                    else
                        MarkItemWatched(movie.id)
                    end if
                    movie.watched = not movie.watched
                end if
            else if btn <> invalid and btn.id = "favorite-button"
                movie = group.itemContent
                if movie.favorite
                    UnmarkItemFavorite(movie.id)
                else
                    MarkItemFavorite(movie.id)
                end if
                movie.favorite = not movie.favorite
            else
                ' If there are no other button matches, check if this is a simple "OK" Dialog & Close if so
                dialog = msg.getRoSGNode()
                if dialog.id = "OKDialog"
                    dialog.unobserveField("buttonSelected")
                    dialog.close = true
                end if
            end if
        else if isNodeEvent(msg, "optionSelected")
            button = msg.getRoSGNode()
            group = sceneManager.callFunc("getActiveScene")
            if button.id = "goto_search" and isValid(group)
                ' Exit out of the side panel
                panel = group.findNode("options")
                panel.visible = false
                if isValid(group.lastFocus)
                    group.lastFocus.setFocus(true)
                else
                    group.setFocus(true)
                end if
                group = CreateSearchPage()
                sceneManager.callFunc("pushScene", group)
                group.findNode("SearchBox").findNode("search_Key").setFocus(true)
                group.findNode("SearchBox").findNode("search_Key").active = true
            else if button.id = "change_server"
                unset_setting("server")
                unset_setting("port")
                SignOut(false)
                sceneManager.callFunc("clearScenes")
                goto app_start
            else if button.id = "sign_out"
                SignOut()
                sceneManager.callFunc("clearScenes")
                goto app_start
            else if button.id = "settings"
                ' Exit out of the side panel
                panel = group.findNode("options")
                panel.visible = false
                if isValid(group) and isValid(group.lastFocus)
                    group.lastFocus.setFocus(true)
                else
                    group.setFocus(true)
                end if
                sceneManager.callFunc("settings")
            end if
        else if isNodeEvent(msg, "selectSubtitlePressed")
            node = m.scene.focusedChild
            if node.focusedChild <> invalid and node.focusedChild.isSubType("JFVideo")
                trackSelected = selectSubtitleTrack(node.Subtitles, node.SelectedSubtitle)
                if trackSelected <> invalid and trackSelected <> -2
                    changeSubtitleDuringPlayback(trackSelected)
                end if
            end if
        else if isNodeEvent(msg, "selectPlaybackInfoPressed")
            node = m.scene.focusedChild
            if node.focusedChild <> invalid and node.focusedChild.isSubType("JFVideo")
                info = GetPlaybackInfo()
                show_dialog(tr("Playback Information"), info)
            end if
        else if isNodeEvent(msg, "state")
            node = msg.getRoSGNode()
            if isValid(node) and isValid(node.state)
                if node.selectedItemType = "TvChannel" and node.state = "finished"
                    video = CreateVideoPlayerGroup(node.id)
                    m.global.sceneManager.callFunc("pushScene", video)
                    m.global.sceneManager.callFunc("deleteSceneAtIndex", 2)
                else if node.state = "finished"
                    node.control = "stop"

                    ' If node allows retrying using Transcode Url, give that shot
                    if isValid(node.retryWithTranscoding) and node.retryWithTranscoding
                        retryVideo = CreateVideoPlayerGroup(node.Id, invalid, node.audioIndex, true, false)
                        m.global.sceneManager.callFunc("popScene")
                        if isValid(retryVideo)
                            m.global.sceneManager.callFunc("pushScene", retryVideo)
                        end if
                    else if not isValid(node.showID)
                        sceneManager.callFunc("popScene")
                    else
                        autoPlayNextEpisode(node.id, node.showID)
                    end if
                end if
            end if
        else if type(msg) = "roDeviceInfoEvent"
            event = msg.GetInfo()

            if event.exitedScreensaver = true
                sceneManager.callFunc("resetTime")
                group = sceneManager.callFunc("getActiveScene")
                if isValid(group) and isValid(group.subtype())
                    ' refresh the current view
                    if group.subtype() = "Home"
                        currentTime = CreateObject("roDateTime").AsSeconds()
                        group.timeLastRefresh = currentTime
                        group.callFunc("refresh")
                    end if
                    ' todo: add other screens to be refreshed - movie detail, tv series, episode list etc.
                end if
            else if isValid(event.audioGuideEnabled)
                tmpGlobalDevice = m.global.device
                tmpGlobalDevice.AddReplace("isaudioguideenabled", event.audioGuideEnabled)

                ' update global device array
                m.global.setFields({ device: tmpGlobalDevice })
            else if isValid(event.Mode)
                ' Indicates the current global setting for the Caption Mode property, which may be one of the following values:
                ' "On"
                ' "Off"
                ' "Instant replay"
                ' "When mute" (Only returned for a TV; this option is not available on STBs).
                print "event.Mode = ", event.Mode
                if isValid(event.Mute)
                    print "event.Mute = ", event.Mute
                end if
            else if isValid(event.linkStatus)
                ' True if the device currently seems to have an active network connection.
                print "event.linkStatus = ", event.linkStatus
            else if isValid(event.generalMemoryLevel)
                ' This event will be sent first when the OS transitions from "normal" to "low" state and will continue to be sent while in "low" or "critical" states.
                '   - "normal" means that the general memory is within acceptable levels
                '   - "low" means that the general memory is below acceptable levels but not critical
                '   - "critical" means that general memory are at dangerously low level and that the OS may force terminate the application
                print "event.generalMemoryLevel = ", event.generalMemoryLevel
            else if isValid(event.audioCodecCapabilityChanged)
                ' The audio codec capability has changed if true.
                print "event.audioCodecCapabilityChanged = ", event.audioCodecCapabilityChanged

                PostDeviceProfile()
            else if isValid(event.videoCodecCapabilityChanged)
                ' The video codec capability has changed if true.
                print "event.videoCodecCapabilityChanged = ", event.videoCodecCapabilityChanged

                PostDeviceProfile()
            else if isValid(event.appFocus)
                ' It is set to False when the System Overlay (such as the confirm partner button HUD or the caption control overlay) takes focus and True when the channel regains focus
                print "event.appFocus = ", event.appFocus
            else
                print "Unhandled roDeviceInfoEvent:"
                print msg.GetInfo()
            end if
        else if type(msg) = "roInputEvent"
            if msg.IsInput()
                info = msg.GetInfo()
                if info.DoesExist("mediatype") and info.DoesExist("contentid")
                    inputEventVideo = {
                        id: info.contentId,
                        type: "video"
                    }

                    m.global.queueManager.callFunc("clear")
                    m.global.queueManager.callFunc("push", inputEventVideo)
                    m.global.queueManager.callFunc("playQueue")
                end if
            end if
        else if isNodeEvent(msg, "dataReturned")
            popupNode = msg.getRoSGNode()
            if isValid(popupNode) and isValid(popupNode.returnData)
                selectedItem = m.global.queueManager.callFunc("getHold")
                m.global.queueManager.callFunc("clearHold")

                if isValid(selectedItem) and selectedItem.count() > 0 and isValid(selectedItem[0])
                    if popupNode.returnData.indexselected = 0
                        'Resume video from resume point
                        startingPoint = 0

                        if isValid(selectedItem[0].json) and isValid(selectedItem[0].json.UserData) and isValid(selectedItem[0].json.UserData.PlaybackPositionTicks)
                            if selectedItem[0].json.UserData.PlaybackPositionTicks > 0
                                startingPoint = selectedItem[0].json.UserData.PlaybackPositionTicks
                            end if
                        end if

                        selectedItem[0].startingPoint = startingPoint
                        m.global.queueManager.callFunc("clear")
                        m.global.queueManager.callFunc("push", selectedItem[0])
                        m.global.queueManager.callFunc("playQueue")
                    else if popupNode.returnData.indexselected = 1
                        'Start Over from beginning selected, set position to 0
                        selectedItem[0].startingPoint = 0
                        m.global.queueManager.callFunc("clear")
                        m.global.queueManager.callFunc("push", selectedItem[0])
                        m.global.queueManager.callFunc("playQueue")
                    else if popupNode.returnData.indexselected = 2
                        ' User chose Go to series
                        CreateSeriesDetailsGroup(selectedItem[0].json.SeriesId)
                    else if popupNode.returnData.indexselected = 3
                        ' User chose Go to season
                        CreateSeasonDetailsGroupByID(selectedItem[0].json.SeriesId, selectedItem[0].json.seasonID)
                    else if popupNode.returnData.indexselected = 4
                        ' User chose Go to episode
                        CreateMovieDetailsGroup(selectedItem[0])
                    end if
                end if
            end if
        else
            print "Unhandled " type(msg)
            print msg
        end if
    end while

end sub
