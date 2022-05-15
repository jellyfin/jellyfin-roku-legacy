function CreateServerGroup()
    screen = CreateObject("roSGNode", "SetServerScreen")
    screen.optionsAvailable = true
    m.global.sceneManager.callFunc("pushScene", screen)
    port = CreateObject("roMessagePort")
    m.colors = {}

    if get_setting("server") <> invalid
        screen.serverUrl = get_setting("server")
    end if
    m.viewModel = {}
    button = screen.findNode("submit")
    button.observeField("buttonSelected", port)
    'create delete saved server option
    new_options = []
    sidepanel = screen.findNode("options")
    opt = CreateObject("roSGNode", "OptionsButton")
    opt.title = tr("Delete Saved")
    opt.id = "delete_saved"
    opt.observeField("optionSelected", port)
    new_options.push(opt)
    sidepanel.options = new_options
    sidepanel.observeField("closeSidePanel", port)

    screen.observeField("backPressed", port)

    while true
        msg = wait(0, port)
        print type(msg), msg
        if type(msg) = "roSGScreenEvent" and msg.isScreenClosed()
            return "false"
        else if isNodeEvent(msg, "backPressed")
            return "backPressed"
        else if isNodeEvent(msg, "closeSidePanel")
            screen.setFocus(true)
            serverPicker = screen.findNode("serverPicker")
            serverPicker.setFocus(true)
        else if type(msg) = "roSGNodeEvent"
            node = msg.getNode()
            if node = "submit"
                serverUrl = standardize_jellyfin_url(screen.serverUrl)
                'If this is a different server from what we know, reset username/password setting
                if get_setting("server") <> serverUrl
                    set_setting("username", "")
                    set_setting("password", "")
                end if
                set_setting("server", serverUrl)
                ' Show Connecting to Server spinner
                dialog = createObject("roSGNode", "ProgressDialog")
                dialog.title = tr("Connecting to Server")
                m.scene.dialog = dialog

                serverInfoResult = ServerInfo()

                dialog.close = true

                if serverInfoResult = invalid
                    ' Maybe don't unset setting, but offer as a prompt
                    ' Server not found, is it online? New values / Retry
                    print "Server not found, is it online? New values / Retry"
                    screen.errorMessage = tr("Server not found, is it online?")
                    SignOut(false)
                else if serverInfoResult.Error <> invalid and serverInfoResult.Error
                    ' If server redirected received, update the URL
                    if serverInfoResult.UpdatedUrl <> invalid
                        serverUrl = serverInfoResult.UpdatedUrl
                        set_setting("server", serverUrl)
                    end if
                    ' Display Error Message to user
                    message = tr("Error: ")
                    if serverInfoResult.ErrorCode <> invalid
                        message = message + "[" + serverInfoResult.ErrorCode.toStr() + "] "
                    end if
                    screen.errorMessage = message + tr(serverInfoResult.ErrorMessage)
                    SignOut(false)
                else
                    screen.visible = false
                    if serverInfoResult.serverName <> invalid
                        return serverInfoResult.ServerName + " (Saved)"
                    else
                        return "Saved"
                    end if
                end if
            else if node = "delete_saved"
                serverPicker = screen.findNode("serverPicker")
                itemToDelete = serverPicker.content.getChild(serverPicker.itemFocused)
                urlToDelete = itemToDelete.baseUrl
                if urlToDelete <> invalid
                    DeleteFromServerList(urlToDelete)
                    serverPicker.content.removeChild(itemToDelete)
                    sidepanel.visible = false
                    serverPicker.setFocus(true)
                end if
            end if
        end if
    end while

    ' Just hide it when done, in case we need to come back
    screen.visible = false
    return ""
end function

function CreateUserSelectGroup(users = [])
    if users.count() = 0
        return ""
    end if
    group = CreateObject("roSGNode", "UserSelect")
    m.global.sceneManager.callFunc("pushScene", group)
    port = CreateObject("roMessagePort")

    group.itemContent = users
    group.findNode("userRow").observeField("userSelected", port)
    group.findNode("alternateOptions").observeField("itemSelected", port)
    group.observeField("backPressed", port)
    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" and msg.isScreenClosed()
            group.visible = false
            return -1
        else if isNodeEvent(msg, "backPressed")
            return "backPressed"
        else if type(msg) = "roSGNodeEvent" and msg.getField() = "userSelected"
            return msg.GetData()
        else if type(msg) = "roSGNodeEvent" and msg.getField() = "itemSelected"
            if msg.getData() = 0
                return ""
            end if
        end if
    end while

    ' Just hide it when done, in case we need to come back
    group.visible = false
    return ""
end function

function CreateSigninGroup(user = "")
    ' Get and Save Jellyfin user login credentials
    group = CreateObject("roSGNode", "ConfigScene")
    m.global.sceneManager.callFunc("pushScene", group)
    port = CreateObject("roMessagePort")

    group.findNode("prompt").text = tr("Sign In")

    'Load in any saved server data and see if we can just log them in...
    server = get_setting("server")
    if server <> invalid
        server = LCase(server)'Saved server data is always lowercase
    end if
    saved = get_setting("saved_servers")
    if saved <> invalid
        savedServers = ParseJson(saved)
        for each item in savedServers.serverList
            if item.baseUrl = server and item.username <> invalid and item.password <> invalid
                get_token(item.username, item.password)
                if get_setting("active_user") <> invalid
                    return "true"
                end if
            end if
        end for
    end if

    config = group.findNode("configOptions")
    username_field = CreateObject("roSGNode", "ConfigData")
    username_field.label = tr("Username")
    username_field.field = "username"
    username_field.type = "string"
    if user = "" and get_setting("username") <> invalid
        username_field.value = get_setting("username")
    else
        username_field.value = user
    end if
    password_field = CreateObject("roSGNode", "ConfigData")
    password_field.label = tr("Password")
    password_field.field = "password"
    password_field.type = "password"
    if get_setting("password") <> invalid
        password_field.value = get_setting("password")
    end if
    ' Add checkbox for saving credentials
    checkbox = group.findNode("onOff")
    items = CreateObject("roSGNode", "ContentNode")
    items.role = "content"
    saveCheckBox = CreateObject("roSGNode", "ContentNode")
    saveCheckBox.title = tr("Save Credentials?")
    items.appendChild(saveCheckBox)
    checkbox.content = items
    checkbox.checkedState = [true]

    items = [username_field, password_field]
    config.configItems = items

    button = group.findNode("submit")
    button.observeField("buttonSelected", port)

    config = group.findNode("configOptions")

    username = config.content.getChild(0)
    password = config.content.getChild(1)

    group.observeField("backPressed", port)

    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" and msg.isScreenClosed()
            group.visible = false
            return "false"
        else if isNodeEvent(msg, "backPressed")
            group.unobserveField("backPressed")
            group.backPressed = false
            return "backPressed"
        else if type(msg) = "roSGNodeEvent"
            node = msg.getNode()
            if node = "submit"
                ' Validate credentials
                get_token(username.value, password.value)
                if get_setting("active_user") <> invalid
                    set_setting("username", username.value)
                    set_setting("password", password.value)
                    if checkbox.checkedState[0] = true
                        'Update our saved server list, so next time the user can just click and go
                        UpdateSavedServerList()
                    end if
                    return "true"
                end if
                print "Login attempt failed..."
                group.findNode("alert").text = tr("Login attempt failed.")
            end if
        end if
    end while

    ' Just hide it when done, in case we need to come back
    group.visible = false
    return ""
end function

function CreateHomeGroup()
    ' Main screen after logging in. Shows the user's libraries
    group = CreateObject("roSGNode", "Home")
    group.overhangTitle = tr("Home")
    group.optionsAvailable = true

    group.observeField("selectedItem", m.port)
    group.observeField("quickPlayNode", m.port)

    sidepanel = group.findNode("options")
    sidepanel.observeField("closeSidePanel", m.port)
    new_options = []
    options_buttons = [
        { "title": "Search", "id": "goto_search" },
        { "title": "Change server", "id": "change_server" },
        { "title": "Sign out", "id": "sign_out" }
    ]
    for each opt in options_buttons
        o = CreateObject("roSGNode", "OptionsButton")
        o.title = tr(opt.title)
        o.id = opt.id
        o.observeField("optionSelected", m.port)
        new_options.push(o)
    end for

    ' Add settings option to menu
    o = CreateObject("roSGNode", "OptionsButton")
    o.title = "Settings"
    o.id = "settings"
    o.observeField("optionSelected", m.port)
    new_options.push(o)

    ' And a profile button
    user_node = CreateObject("roSGNode", "OptionsData")
    user_node.id = "active_user"
    user_node.title = tr("Profile")
    user_node.base_title = tr("Profile")
    user_options = []
    for each user in AvailableUsers()
        user_options.push({ display: user.username + "@" + user.server, value: user.id })
    end for
    user_node.choices = user_options
    user_node.value = get_setting("active_user")
    new_options.push(user_node)

    sidepanel.options = new_options

    return group
end function

function CreateMovieDetailsGroup(movie)
    group = CreateObject("roSGNode", "MovieDetails")
    group.overhangTitle = movie.title
    group.optionsAvailable = false
    m.global.sceneManager.callFunc("pushScene", group)

    movie = ItemMetaData(movie.id)
    group.itemContent = movie

    buttons = group.findNode("buttons")
    for each b in buttons.getChildren(-1, 0)
        b.observeField("buttonSelected", m.port)
    end for

    extras = group.findNode("extrasGrid")
    extras.observeField("selectedItem", m.port)
    extras.callFunc("loadPeople", movie.json)

    return group
end function

function CreateSeriesDetailsGroup(series)
    group = CreateObject("roSGNode", "TVShowDetails")
    group.optionsAvailable = false
    m.global.sceneManager.callFunc("pushScene", group)

    group.itemContent = ItemMetaData(series.id)
    group.seasonData = TVSeasons(series.id)

    group.observeField("seasonSelected", m.port)

    extras = group.findNode("extrasGrid")
    extras.observeField("selectedItem", m.port)
    extras.callFunc("loadPeople", group.itemcontent.json)

    return group
end function

' Shows details on selected artist. Bio, image, and list of available albums
function CreateMusicArtistDetailsGroup(musicartist)
    group = CreateObject("roSGNode", "MusicArtistDetails")
    m.global.sceneManager.callFunc("pushScene", group)

    group.itemContent = ItemMetaData(musicartist.id)
    group.musicArtistAlbumData = MusicAlbumList(musicartist.id)

    group.observeField("musicAlbumSelected", m.port)

    return group
end function

' Shows details on selected album. Description text, image, and list of available songs
function CreateMusicAlbumDetailsGroup(album)
    group = CreateObject("roSGNode", "MusicAlbumDetails")
    m.global.sceneManager.callFunc("pushScene", group)

    group.itemContent = ItemMetaData(album.id)
    group.musicArtistAlbumData = MusicSongList(album.id)

    ' Watch for user clicking on a song
    group.observeField("musicSongSelected", m.port)

    return group
end function

function CreateSeasonDetailsGroup(series, season)
    group = CreateObject("roSGNode", "TVEpisodes")
    group.optionsAvailable = false
    m.global.sceneManager.callFunc("pushScene", group)

    group.seasonData = ItemMetaData(season.id).json
    group.objects = TVEpisodes(series.id, season.id)

    group.observeField("episodeSelected", m.port)
    group.observeField("quickPlayNode", m.port)

    return group
end function

function CreateItemGrid(libraryItem)
    group = CreateObject("roSGNode", "ItemGrid")
    group.parentItem = libraryItem
    group.optionsAvailable = true
    group.observeField("selectedItem", m.port)
    return group
end function

function CreateSearchPage()
    ' Search + Results Page
    group = CreateObject("roSGNode", "SearchResults")

    search = group.findNode("SearchBox")
    search.observeField("search_value", m.port)

    options = group.findNode("SearchSelect")
    options.observeField("itemSelected", m.port)

    return group
end function

sub CreateSidePanel(buttons, options)
    group = CreateObject("roSGNode", "OptionsSlider")
    group.buttons = buttons
    group.options = options
end sub

function CreateVideoPlayerGroup(video_id, mediaSourceId = invalid, audio_stream_idx = 1)
    ' Video is Playing
    video = VideoPlayer(video_id, mediaSourceId, audio_stream_idx, defaultSubtitleTrackFromVid(video_id))
    if video = invalid then return invalid
    video.observeField("selectSubtitlePressed", m.port)
    video.observeField("state", m.port)

    return video
end function

sub controlaudioplay()
    if (m.audio.state = "finished") 
        m.audio.control = "stop"
        m.audio.control = "none"
    end if
end sub

' Play Audio
function CreateAudioPlayerGroup(audio)
    print "[INFO] Playing ", audio.title
    
    songData = AudioItem(audio.id)

    m.audio = createObject("RoSGNode", "Audio")
    m.audio.observeField("state", "controlaudioplay")
    m.audio.content = createObject("RoSGNode", "ContentNode")

    params = {}

    params.append({
        "Static": "true",
        "Container": songData.mediaSources[0].container,
    })

    params.MediaSourceId = songData.mediaSources[0].id

    m.audio.content.url = buildURL(Substitute("Audio/{0}/stream", audio.id), params)
    m.audio.content.title = audio.title
    m.audio.content.streamformat = songData.mediaSources[0].container

    m.audio.control = "stop"
    m.audio.control = "none"
    m.audio.control = "play"

    return ""
end function

function CreatePersonView(personData as object) as object
    person = CreateObject("roSGNode", "PersonDetails")
    m.global.SceneManager.callFunc("pushScene", person)

    info = ItemMetaData(personData.id)
    person.itemContent = info

    person.setFocus(true)
    person.observeField("selectedItem", m.port)
    person.findNode("favorite-button").observeField("buttonSelected", m.port)

    return person
end function

function CreatePhotoPage(photo)
    group = CreateObject("roSGNode", "PhotoDetails")
    group.optionsAvailable = true
    m.global.sceneManager.callFunc("pushScene", group)

    group.itemContent = photo

    return group

end function

sub UpdateSavedServerList()
    server = get_setting("server")
    username = get_setting("username")
    password = get_setting("password")

    if server = invalid or username = invalid or password = invalid
        return
    end if

    server = LCase(server)'Saved server data is always lowercase

    saved = get_setting("saved_servers")
    if saved <> invalid
        savedServers = ParseJson(saved)
        if savedServers.serverList <> invalid and savedServers.serverList.Count() > 0
            newServers = { serverList: [] }
            for each item in savedServers.serverList
                if item.baseUrl = server
                    item.username = username
                    item.password = password
                end if
                newServers.serverList.Push(item)
            end for
            set_setting("saved_servers", FormatJson(newServers))
        end if
    end if
end sub
