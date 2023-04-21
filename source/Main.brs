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
    m.scene = m.screen.CreateScene("JFScene")
    m.screen.show() ' vscode_rale_tracker_entry

    ' Set any initial Global Variables
    m.global = m.screen.getGlobalNode()

    playstateTask = CreateObject("roSGNode", "PlaystateTask")
    playstateTask.id = "playstateTask"

    sceneManager = CreateObject("roSGNode", "SceneManager")

    m.global.addFields({ app_loaded: false, playstateTask: playstateTask, sceneManager: sceneManager })
    m.global.addFields({ queueManager: CreateObject("roSGNode", "QueueManager") })
    m.global.addFields({ audioPlayer: CreateObject("roSGNode", "AudioPlayer") })

    app_start:
    ' First thing to do is validate the ability to use the API
    if not LoginFlow() then return
    ' remove previous scenes from the stack
    sceneManager.callFunc("clearScenes")
    ' save user config
    m.global.addFields({ userConfig: m.user.configuration })
    ' load home page
    sceneManager.currentUser = m.user.Name
    group = CreateHomeGroup()
    group.callFunc("loadLibraries")
    sceneManager.callFunc("pushScene", group)

    m.scene.observeField("exit", m.port)

    ' Downloads and stores a fallback font to tmp:/
    configEncoding = api_API().system.getconfigurationbyname("encoding")

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
    appInfo = CreateObject("roAppInfo")
    if appInfo.GetVersion() <> get_setting("LastRunVersion")
        ' Ensure the user hasn't disabled Whats New popups
        if get_user_setting("load.allowwhatsnew") = "true"
            set_setting("LastRunVersion", appInfo.GetVersion())
            dialog = createObject("roSGNode", "WhatsNewDialog")
            m.scene.dialog = dialog
            m.scene.dialog.observeField("buttonSelected", m.port)
        end if
    end if

    ' Handle input messages
    input = CreateObject("roInput")
    input.SetMessagePort(m.port)

    m.device = CreateObject("roDeviceInfo")
    m.device.setMessagePort(m.port)
    m.device.EnableScreensaverExitedEvent(true)
    m.device.EnableAppFocusEvent(false)

    ' Check if we were sent content to play with the startup command (Deep Link)
    if isValidAndNotEmpty(args.mediaType) and isValidAndNotEmpty(args.contentId)
        video = CreateVideoPlayerGroup(args.contentId)

        if isValid(video) and video.errorMsg <> "introaborted"
            sceneManager.callFunc("pushScene", video)
        else
            dialog = createObject("roSGNode", "Dialog")
            dialog.id = "OKDialog"
            dialog.title = tr("Not found")
            dialog.message = tr("The requested content does not exist on the server")
            dialog.buttons = [tr("OK")]
            m.scene.dialog = dialog
            m.scene.dialog.observeField("buttonSelected", m.port)
        end if
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
            if itemNode = invalid or itemNode.id = "" then return
            if itemNode.type = "Episode" or itemNode.type = "Movie" or itemNode.type = "Video"
                if itemNode.type = "Episode" and itemNode.selectedAudioStreamIndex <> invalid and itemNode.selectedAudioStreamIndex > 1
                    video = CreateVideoPlayerGroup(itemNode.id, invalid, itemNode.selectedAudioStreamIndex)
                else
                    video = CreateVideoPlayerGroup(itemNode.id)
                end if
                if video <> invalid and video.errorMsg <> "introaborted"
                    sceneManager.callFunc("pushScene", video)
                end if

                if LCase(group.subtype()) = "tvepisodes"
                    if isValid(group.lastFocus)
                        group.lastFocus.setFocus(true)
                    end if
                end if
            end if
        else if isNodeEvent(msg, "selectedItem")
            ' If you select a library from ANYWHERE, follow this flow
            selectedItem = msg.getData()

            m.selectedItemType = selectedItem.type

            if selectedItem.type = "CollectionFolder" or selectedItem.type = "BoxSet"
                if selectedItem.collectionType = "movies"
                    group = CreateMovieLibraryView(selectedItem)
                else if selectedItem.collectionType = "music"
                    group = CreateMusicLibraryView(selectedItem)
                else
                    group = CreateItemGrid(selectedItem)
                end if
                sceneManager.callFunc("pushScene", group)
            else if selectedItem.type = "Folder" and selectedItem.json.type = "Genre"
                ' User clicked on a genre folder
                if selectedItem.json.MovieCount > 0
                    group = CreateMovieLibraryView(selectedItem)
                else
                    group = CreateItemGrid(selectedItem)
                end if
                sceneManager.callFunc("pushScene", group)
            else if selectedItem.type = "Folder" and selectedItem.json.type = "MusicGenre"
                group = CreateMusicLibraryView(selectedItem)
                sceneManager.callFunc("pushScene", group)
            else if selectedItem.type = "UserView" or selectedItem.type = "Folder" or selectedItem.type = "Channel" or selectedItem.type = "Boxset"
                group = CreateItemGrid(selectedItem)
                sceneManager.callFunc("pushScene", group)
            else if selectedItem.type = "Episode"
                ' play episode
                ' todo: create an episode page to link here
                video_id = selectedItem.id
                if selectedItem.selectedAudioStreamIndex <> invalid and selectedItem.selectedAudioStreamIndex > 1
                    video = CreateVideoPlayerGroup(video_id, invalid, selectedItem.selectedAudioStreamIndex)
                else
                    video = CreateVideoPlayerGroup(video_id)
                end if
                if video <> invalid and video.errorMsg <> "introaborted"
                    sceneManager.callFunc("pushScene", video)
                end if
            else if selectedItem.type = "Series"
                group = CreateSeriesDetailsGroup(selectedItem.json)
            else if selectedItem.type = "Season"
                group = CreateSeasonDetailsGroupByID(selectedItem.json.SeriesId, selectedItem.id)
            else if selectedItem.type = "Movie"
                ' open movie detail page
                group = CreateMovieDetailsGroup(selectedItem)
            else if selectedItem.type = "Person"
                CreatePersonView(selectedItem)
            else if selectedItem.type = "TvChannel" or selectedItem.type = "Video" or selectedItem.type = "Program"
                ' play channel feed
                video_id = selectedItem.id

                ' Show Channel Loading spinner
                dialog = createObject("roSGNode", "ProgressDialog")
                dialog.title = tr("Loading Channel Data")
                m.scene.dialog = dialog

                if LCase(selectedItem.subtype()) = "extrasdata"
                    video = CreateVideoPlayerGroup(video_id, invalid, 1, false, true, false)
                else
                    video = CreateVideoPlayerGroup(video_id)
                end if

                dialog.close = true

                if video <> invalid and video.errorMsg <> "introaborted"
                    sceneManager.callFunc("pushScene", video)
                else
                    dialog = createObject("roSGNode", "Dialog")
                    dialog.id = "OKDialog"
                    dialog.title = tr("Error loading Channel Data")
                    dialog.message = tr("Unable to load Channel Data from the server")
                    dialog.buttons = [tr("OK")]
                    m.scene.dialog = dialog
                    m.scene.dialog.observeField("buttonSelected", m.port)
                end if
            else if selectedItem.type = "Photo"
                ' Nothing to do here, handled in ItemGrid
            else if selectedItem.type = "MusicArtist"
                group = CreateArtistView(selectedItem.json)
                if not isValid(group)
                    message_dialog(tr("Unable to find any albums or songs belonging to this artist"))
                end if
            else if selectedItem.type = "MusicAlbum"
                group = CreateAlbumView(selectedItem.json)
            else if selectedItem.type = "Playlist"
                group = CreatePlaylistView(selectedItem.json)
            else if selectedItem.type = "Audio"
                m.global.queueManager.callFunc("clear")
                m.global.queueManager.callFunc("resetShuffle")
                m.global.queueManager.callFunc("push", selectedItem.json)
                m.global.queueManager.callFunc("playQueue")
            else
                ' TODO - switch on more node types
                message_dialog("This type is not yet supported: " + selectedItem.type + ".")
            end if
        else if isNodeEvent(msg, "movieSelected")
            ' If you select a movie from ANYWHERE, follow this flow
            node = getMsgPicker(msg, "picker")
            group = CreateMovieDetailsGroup(node)
        else if isNodeEvent(msg, "seriesSelected")
            ' If you select a TV Series from ANYWHERE, follow this flow
            node = getMsgPicker(msg, "picker")
            group = CreateSeriesDetailsGroup(node)
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

        else if isNodeEvent(msg, "episodeSelected")
            ' If you select a TV Episode from ANYWHERE, follow this flow
            m.selectedItemType = "Episode"
            node = getMsgPicker(msg, "picker")
            video_id = node.id
            if node.selectedAudioStreamIndex <> invalid and node.selectedAudioStreamIndex > 1
                video = CreateVideoPlayerGroup(video_id, invalid, node.selectedAudioStreamIndex)
            else
                video = CreateVideoPlayerGroup(video_id)
            end if
            if video <> invalid and video.errorMsg <> "introaborted"
                sceneManager.callFunc("pushScene", video)
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
            m.selectedItemType = node.type
            if node.type = "Series"
                group = CreateSeriesDetailsGroup(node)
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

                ' Check if a specific Audio Stream was selected
                audio_stream_idx = 1
                if isValid(group) and isValid(group.selectedAudioStreamIndex)
                    audio_stream_idx = group.selectedAudioStreamIndex
                end if

                ' Check to see if a specific video "version" was selected
                mediaSourceId = invalid
                if isValid(group) and isValid(group.selectedVideoStreamId)
                    mediaSourceId = group.selectedVideoStreamId
                end if
                video_id = group.id
                video = CreateVideoPlayerGroup(video_id, mediaSourceId, audio_stream_idx)
                if isValid(video) and video.errorMsg <> "introaborted"
                    sceneManager.callFunc("pushScene", video)
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
                dialog = createObject("roSGNode", "ProgressDialog")
                dialog.title = tr("Loading trailer")
                m.scene.dialog = dialog
                audio_stream_idx = 1
                mediaSourceId = invalid
                video_id = group.id

                trailerData = api_API().users.getlocaltrailers(get_setting("active_user"), group.id)
                video = invalid

                if isValid(trailerData) and isValid(trailerData[0]) and isValid(trailerData[0].id)
                    video_id = trailerData[0].id
                    video = CreateVideoPlayerGroup(video_id, mediaSourceId, audio_stream_idx, false, false)
                end if

                if isValid(video) and video.errorMsg <> "introaborted"
                    sceneManager.callFunc("pushScene", video)
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
                if m.selectedItemType = "TvChannel" and node.state = "finished"
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
                        if video.errorMsg = ""
                            autoPlayNextEpisode(node.id, node.showID)
                        else
                            sceneManager.callFunc("popScene")
                        end if
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
            else
                print "Unhandled roDeviceInfoEvent:"
                print msg.GetInfo()
            end if
        else if type(msg) = "roInputEvent"
            if msg.IsInput()
                info = msg.GetInfo()
                if info.DoesExist("mediatype") and info.DoesExist("contentid")
                    video = CreateVideoPlayerGroup(info.contentId)
                    if video <> invalid and video.errorMsg <> "introaborted"
                        sceneManager.callFunc("pushScene", video)
                    else
                        dialog = createObject("roSGNode", "Dialog")
                        dialog.id = "OKDialog"
                        dialog.title = tr("Not found")
                        dialog.message = tr("The requested content does not exist on the server")
                        dialog.buttons = [tr("OK")]
                        m.scene.dialog = dialog
                        m.scene.dialog.observeField("buttonSelected", m.port)
                    end if
                end if
            end if
        else
            print "Unhandled " type(msg)
            print msg
        end if
    end while

end sub
