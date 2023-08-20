function LoginFlow(startOver = false as boolean)
    'Collect Jellyfin server and user information
    start_login:

    serverUrl = get_setting("server")
    if isValid(serverUrl)
        print "Previous server connection saved to registry"
        startOver = not session.server.UpdateURL(serverUrl)
        if startOver
            print "Could not connect to previously saved server."
        end if
    else
        startOver = true
        print "No previous server connection saved to registry"
    end if

    invalidServer = true
    if not startOver
        ' Show Connecting to Server spinner
        dialog = createObject("roSGNode", "ProgressDialog")
        dialog.title = tr("Connecting to Server")
        m.scene.dialog = dialog
        invalidServer = ServerInfo().Error
        dialog.close = true
    end if

    m.serverSelection = "Saved"
    if startOver or invalidServer
        print "Get server details"
        SendPerformanceBeacon("AppDialogInitiate") ' Roku Performance monitoring - Dialog Starting
        m.serverSelection = CreateServerGroup()
        SendPerformanceBeacon("AppDialogComplete") ' Roku Performance monitoring - Dialog Closed
        if m.serverSelection = "backPressed"
            print "backPressed"
            m.global.sceneManager.callFunc("clearScenes")
            return false
        end if
        SaveServerList()
    end if

    activeUser = get_setting("active_user")
    if activeUser = invalid
        print "No active user found in registry"
        SendPerformanceBeacon("AppDialogInitiate") ' Roku Performance monitoring - Dialog Starting
        publicUsers = GetPublicUsers()
        if publicUsers.count()
            publicUsersNodes = []
            for each item in publicUsers
                user = CreateObject("roSGNode", "PublicUserData")
                user.id = item.Id
                user.name = item.Name
                if isValid(item.PrimaryImageTag)
                    user.ImageURL = UserImageURL(user.id, { "tag": item.PrimaryImageTag })
                end if
                publicUsersNodes.push(user)
            end for
            userSelected = CreateUserSelectGroup(publicUsersNodes)
            if userSelected = "backPressed"
                SendPerformanceBeacon("AppDialogComplete") ' Roku Performance monitoring - Dialog Closed
                return LoginFlow(true)
            else
                'Try to login without password. If the token is valid, we're done
                userData = get_token(userSelected, "")
                if isValid(userData)
                    session.user.Login(userData)
                    LoadUserPreferences()
                    LoadUserAbilities()
                    SendPerformanceBeacon("AppDialogComplete") ' Roku Performance monitoring - Dialog Closed
                    return true
                end if
            end if
        else
            userSelected = ""
        end if
        passwordEntry = CreateSigninGroup(userSelected)
        SendPerformanceBeacon("AppDialogComplete") ' Roku Performance monitoring - Dialog Closed
        if passwordEntry = "backPressed"
            m.global.sceneManager.callFunc("clearScenes")
            return LoginFlow(true)
        end if
    else
        print "Active user found in registry"
        session.user.Update("id", activeUser)

        myAuthToken = get_user_setting("token")
        if isValid(myAuthToken)
            print "Auth token found in registry"
            session.user.Update("authToken", myAuthToken)
            print "Attempting to use API with auth token"
            currentUser = AboutMe()
            if currentUser = invalid
                print "Auth token is no longer valid - restart login flow"
                unset_user_setting("token")
                unset_setting("active_user")
                session.user.Logout()
                goto start_login
            else
                print "Success! Auth token is still valid"
                session.user.Login(currentUser)
            end if
        else
            print "No auth token found in registry"
            myUsername = get_setting("username")
            myPassword = get_setting("password")
            userData = invalid

            if isValid(myUsername) and isValid(myPassword)
                if myUsername <> ""
                    print "Username and password found in registry. Attempting to login"
                    userData = get_token(myUsername, myPassword)
                else
                    print "Username in registry is an empty string"
                    unset_setting("username")
                    unset_setting("password")
                end if
            else if isValid(myUsername) and not isValid(myPassword)
                print "Username found in registry but no password"
                if myUsername <> ""
                    print "Attempting to login with no password"
                    userData = get_token(myUsername, "")
                else
                    print "Username in registry is an empty string"
                    unset_setting("username")
                end if

            else if not isValid(myUsername) and not isValid(myPassword)
                print "Neither username nor password found in registry - restart login flow"
                unset_setting("active_user")
                session.user.Logout()
                goto start_login
            end if

            if isValid(userData)
                print "login success!"
                session.user.Login(userData)
            end if
        end if
    end if

    if m.global.session.user.id = invalid or m.global.session.user.authToken = invalid
        print "Login failed, restart flow"
        unset_setting("active_user")
        session.user.Logout()
        goto start_login
    end if

    LoadUserPreferences()
    LoadUserAbilities()
    m.global.sceneManager.callFunc("clearScenes")

    return true
end function

sub SaveServerList()
    'Save off this server to our list of saved servers for easier navigation between servers
    server = m.global.session.server.url
    saved = get_setting("saved_servers")
    if isValid(server)
        server = LCase(server)'Saved server data is always lowercase
    end if
    entryCount = 0
    addNewEntry = true
    savedServers = { serverList: [] }
    if isValid(saved)
        savedServers = ParseJson(saved)
        entryCount = savedServers.serverList.Count()
        if isValid(savedServers.serverList) and entryCount > 0
            for each item in savedServers.serverList
                if item.baseUrl = server
                    addNewEntry = false
                    exit for
                end if
            end for
        end if
    end if

    if addNewEntry
        if entryCount = 0
            set_setting("saved_servers", FormatJson({ serverList: [{ name: m.serverSelection, baseUrl: server, iconUrl: "pkg:/images/logo-icon120.jpg", iconWidth: 120, iconHeight: 120 }] }))
        else
            savedServers.serverList.Push({ name: m.serverSelection, baseUrl: server, iconUrl: "pkg:/images/logo-icon120.jpg", iconWidth: 120, iconHeight: 120 })
            set_setting("saved_servers", FormatJson(savedServers))
        end if
    end if
end sub

sub DeleteFromServerList(urlToDelete)
    saved = get_setting("saved_servers")
    if isValid(urlToDelete)
        urlToDelete = LCase(urlToDelete)
    end if
    if isValid(saved)
        savedServers = ParseJson(saved)
        newServers = { serverList: [] }
        for each item in savedServers.serverList
            if item.baseUrl <> urlToDelete
                newServers.serverList.Push(item)
            end if
        end for
        set_setting("saved_servers", FormatJson(newServers))
    end if
end sub

' Roku Performance monitoring
sub SendPerformanceBeacon(signalName as string)
    if m.global.app_loaded = false
        m.scene.signalBeacon(signalName)
    end if
end sub

function CreateServerGroup()
    screen = CreateObject("roSGNode", "SetServerScreen")
    screen.optionsAvailable = true
    m.global.sceneManager.callFunc("pushScene", screen)
    port = CreateObject("roMessagePort")
    m.colors = {}

    if isValid(m.global.session.server.url)
        screen.serverUrl = m.global.session.server.url
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
                ' Show Connecting to Server spinner
                dialog = createObject("roSGNode", "ProgressDialog")
                dialog.title = tr("Connecting to Server")
                m.scene.dialog = dialog

                serverUrl = standardize_jellyfin_url(screen.serverUrl)
                'If this is a different server from what we know, reset username/password setting
                if m.global.session.server.url <> serverUrl
                    set_setting("username", "")
                    set_setting("password", "")
                end if
                set_setting("server", serverUrl)

                isConnected = session.server.UpdateURL(serverUrl)
                serverInfoResult = invalid
                if isConnected
                    serverInfoResult = ServerInfo()
                end if
                dialog.close = true

                if isConnected = false or serverInfoResult = invalid
                    ' Maybe don't unset setting, but offer as a prompt
                    ' Server not found, is it online? New values / Retry
                    print "Server not found, is it online? New values / Retry"
                    screen.errorMessage = tr("Server not found, is it online?")
                    SignOut(false)
                else
                    if isValid(serverInfoResult.Error) and serverInfoResult.Error
                        ' If server redirected received, update the URL
                        if isValid(serverInfoResult.UpdatedUrl)
                            serverUrl = serverInfoResult.UpdatedUrl
                            set_setting("server", serverUrl)
                            isConnected = session.server.UpdateURL(serverUrl)
                            if isConnected
                                screen.visible = false
                                return ""
                            end if
                        end if
                        ' Display Error Message to user
                        message = tr("Error: ")
                        if isValid(serverInfoResult.ErrorCode)
                            message = message + "[" + serverInfoResult.ErrorCode.toStr() + "] "
                        end if
                        screen.errorMessage = message + tr(serverInfoResult.ErrorMessage)
                        SignOut(false)
                    else
                        screen.visible = false
                        if isValid(serverInfoResult.serverName)
                            return serverInfoResult.ServerName + " (Saved)"
                        else
                            return "Saved"
                        end if
                    end if
                end if
            else if node = "delete_saved"
                serverPicker = screen.findNode("serverPicker")
                itemToDelete = serverPicker.content.getChild(serverPicker.itemFocused)
                urlToDelete = itemToDelete.baseUrl
                if isValid(urlToDelete)
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
    group = CreateObject("roSGNode", "LoginScene")
    m.global.sceneManager.callFunc("pushScene", group)
    port = CreateObject("roMessagePort")

    group.findNode("prompt").text = tr("Sign In")

    'Load in any saved server data and see if we can just log them in...
    server = m.global.session.server.url
    if isValid(server)
        server = LCase(server)'Saved server data is always lowercase
    end if
    saved = get_setting("saved_servers")
    if isValid(saved)
        savedServers = ParseJson(saved)
        for each item in savedServers.serverList
            if item.baseUrl = server and isValid(item.username) and isValid(item.password)
                userData = get_token(item.username, item.password)
                if isValid(userData)
                    session.user.Login(userData)
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
    registryPassword = get_setting("password")
    if isValid(registryPassword)
        password_field.value = registryPassword
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
    quickConnect = group.findNode("quickConnect")
    ' Quick Connect only supported for server version 10.8+ right now...
    if versionChecker(m.global.session.server.version, "10.8.0")
        ' Add option for Quick Connect
        quickConnect.text = tr("Quick Connect")
        quickConnect.observeField("buttonSelected", port)
    else
        quickConnect.visible = false
    end if

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
                activeUser = get_token(username.value, password.value)
                if isValid(activeUser)
                    session.user.Login(activeUser)
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
            else if node = "quickConnect"
                json = initQuickConnect()
                if json = invalid
                    group.findNode("alert").text = tr("Quick Connect not available.")
                else
                    ' Server user is talking to is at least 10.8 and has quick connect enabled...
                    m.quickConnectDialog = createObject("roSGNode", "QuickConnectDialog")
                    m.quickConnectDialog.quickConnectJson = json
                    m.quickConnectDialog.title = tr("Quick Connect")
                    m.quickConnectDialog.message = [tr("Here is your Quick Connect code: ") + json.Code, tr("(Dialog will close automatically)")]
                    m.quickConnectDialog.buttons = [tr("Cancel")]
                    m.quickConnectDialog.observeField("authenticated", port)
                    m.scene.dialog = m.quickConnectDialog
                end if
            else if msg.getField() = "authenticated"
                authenticated = msg.getData()
                if authenticated = true
                    ' Quick connect authentication was successful...
                    return "true"
                else
                    dialog = createObject("roSGNode", "Dialog")
                    dialog.id = "QuickConnectError"
                    dialog.title = tr("Quick Connect")
                    dialog.buttons = [tr("OK")]
                    dialog.message = tr("There was an error authenticating via Quick Connect.")
                    m.scene.dialog = dialog
                    m.scene.dialog.observeField("buttonSelected", port)
                end if
            else
                ' If there are no other button matches, check if this is a simple "OK" Dialog & Close if so
                dialog = msg.getRoSGNode()
                if dialog.id = "QuickConnectError"
                    dialog.unobserveField("buttonSelected")
                    dialog.close = true
                end if
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
    user_node.value = m.global.session.user.id
    new_options.push(user_node)

    sidepanel.options = new_options

    return group
end function

function CreateMovieDetailsGroup(movie as object) as dynamic
    ' validate movie node
    if not isValid(movie) or not isValid(movie.id) then return invalid

    startLoadingSpinner()
    ' get movie meta data
    movieMetaData = ItemMetaData(movie.id)
    ' validate movie meta data
    if not isValid(movieMetaData)
        stopLoadingSpinner()
        return invalid
    end if
    ' start building MovieDetails view
    group = CreateObject("roSGNode", "MovieDetails")
    group.overhangTitle = movie.title
    group.optionsAvailable = false
    group.trailerAvailable = false
    ' push scene asap (to prevent extra button presses when retriving series/movie info)
    m.global.sceneManager.callFunc("pushScene", group)
    group.itemContent = movieMetaData
    ' local trailers
    trailerData = api.users.GetLocalTrailers(m.global.session.user.id, movie.id)
    if isValid(trailerData)
        group.trailerAvailable = trailerData.Count() > 0
    end if
    ' watch for button presses
    buttons = group.findNode("buttons")
    for each b in buttons.getChildren(-1, 0)
        b.observeField("buttonSelected", m.port)
    end for
    ' setup and load movie extras
    extras = group.findNode("extrasGrid")
    extras.observeField("selectedItem", m.port)
    extras.callFunc("loadParts", movieMetaData.json)
    ' done building MovieDetails view
    stopLoadingSpinner()
    return group
end function

function CreateSeriesDetailsGroup(seriesID as string) as dynamic
    ' validate series node
    if not isValid(seriesID) or seriesID = "" then return invalid

    startLoadingSpinner()
    ' get series meta data
    seriesMetaData = ItemMetaData(seriesID)
    ' validate series meta data
    if not isValid(seriesMetaData)
        stopLoadingSpinner()
        return invalid
    end if
    ' Get season data early in the function so we can check number of seasons.
    seasonData = TVSeasons(seriesID)
    ' Divert to season details if user setting goStraightToEpisodeListing is enabled and only one season exists.
    if m.global.session.user.settings["ui.tvshows.goStraightToEpisodeListing"] = true and seasonData.Items.Count() = 1
        stopLoadingSpinner()
        return CreateSeasonDetailsGroupByID(seriesID, seasonData.Items[0].id)
    end if
    ' start building SeriesDetails view
    group = CreateObject("roSGNode", "TVShowDetails")
    group.optionsAvailable = false
    ' push scene asap (to prevent extra button presses when retriving series/movie info)
    m.global.sceneManager.callFunc("pushScene", group)
    group.itemContent = seriesMetaData
    group.seasonData = seasonData
    ' watch for button presses
    group.observeField("seasonSelected", m.port)
    ' setup and load series extras
    extras = group.findNode("extrasGrid")
    extras.observeField("selectedItem", m.port)
    extras.callFunc("loadParts", seriesMetaData.json)
    ' done building SeriesDetails view
    stopLoadingSpinner()
    return group
end function

' Shows details on selected artist. Bio, image, and list of available albums
function CreateArtistView(artist as object) as dynamic
    ' validate artist node
    if not isValid(artist) or not isValid(artist.id) then return invalid

    musicData = MusicAlbumList(artist.id)
    appearsOnData = AppearsOnList(artist.id)

    if (musicData = invalid or musicData.Items.Count() = 0) and (appearsOnData = invalid or appearsOnData.Items.Count() = 0)
        ' Just songs under artists...
        group = CreateObject("roSGNode", "AlbumView")
        group.pageContent = ItemMetaData(artist.id)

        ' Lookup songs based on artist id
        songList = GetSongsByArtist(artist.id)

        if not isValid(songList)
            ' Lookup songs based on folder parent / child relationship
            songList = MusicSongList(artist.id)
        end if

        if not isValid(songList)
            return invalid
        end if

        group.albumData = songList
        group.observeField("playSong", m.port)
        group.observeField("playAllSelected", m.port)
        group.observeField("instantMixSelected", m.port)
    else
        ' User has albums under artists
        group = CreateObject("roSGNode", "ArtistView")
        group.pageContent = ItemMetaData(artist.id)
        group.musicArtistAlbumData = musicData
        group.musicArtistAppearsOnData = appearsOnData
        group.artistOverview = ArtistOverview(artist.name)

        group.observeField("musicAlbumSelected", m.port)
        group.observeField("playArtistSelected", m.port)
        group.observeField("instantMixSelected", m.port)
        group.observeField("appearsOnSelected", m.port)
    end if

    m.global.sceneManager.callFunc("pushScene", group)

    return group
end function

' Shows details on selected album. Description text, image, and list of available songs
function CreateAlbumView(album as object) as dynamic
    ' validate album node
    if not isValid(album) or not isValid(album.id) then return invalid

    group = CreateObject("roSGNode", "AlbumView")
    m.global.sceneManager.callFunc("pushScene", group)

    group.pageContent = ItemMetaData(album.id)
    group.albumData = MusicSongList(album.id)

    ' Watch for user clicking on a song
    group.observeField("playSong", m.port)

    ' Watch for user click on Play button on album
    group.observeField("playAllSelected", m.port)

    ' Watch for user click on Instant Mix button on album
    group.observeField("instantMixSelected", m.port)

    return group
end function

' Shows details on selected playlist. Description text, image, and list of available items
function CreatePlaylistView(playlist as object) as dynamic
    ' validate playlist node
    if not isValid(playlist) or not isValid(playlist.id) then return invalid

    group = CreateObject("roSGNode", "PlaylistView")
    m.global.sceneManager.callFunc("pushScene", group)

    group.pageContent = ItemMetaData(playlist.id)
    group.albumData = PlaylistItemList(playlist.id)

    ' Watch for user clicking on an item
    group.observeField("playItem", m.port)

    ' Watch for user click on Play button
    group.observeField("playAllSelected", m.port)

    return group
end function

function CreateSeasonDetailsGroup(series as object, season as object) as dynamic
    ' validate series node
    if not isValid(series) or not isValid(series.id) then return invalid
    ' validate season node
    if not isValid(season) or not isValid(season.id) then return invalid

    startLoadingSpinner()
    ' get season meta data
    seasonMetaData = ItemMetaData(season.id)
    ' validate season meta data
    if not isValid(seasonMetaData)
        stopLoadingSpinner()
        return invalid
    end if
    ' start building SeasonDetails view
    group = CreateObject("roSGNode", "TVEpisodes")
    group.optionsAvailable = false
    ' push scene asap (to prevent extra button presses when retriving series/movie info)
    m.global.sceneManager.callFunc("pushScene", group)
    group.seasonData = seasonMetaData.json
    group.objects = TVEpisodes(series.id, season.id)
    ' watch for button presses
    group.observeField("episodeSelected", m.port)
    group.observeField("quickPlayNode", m.port)
    ' finished building SeasonDetails view
    stopLoadingSpinner()
    return group
end function

function CreateSeasonDetailsGroupByID(seriesID as string, seasonID as string) as dynamic
    ' validate parameters
    if seriesID = "" or seasonID = "" then return invalid

    startLoadingSpinner()
    ' get season meta data
    seasonMetaData = ItemMetaData(seasonID)
    ' validate season meta data
    if not isValid(seasonMetaData)
        stopLoadingSpinner()
        return invalid
    end if
    ' start building SeasonDetails view
    group = CreateObject("roSGNode", "TVEpisodes")
    group.optionsAvailable = false
    ' push scene asap (to prevent extra button presses when retriving series/movie info)
    m.global.sceneManager.callFunc("pushScene", group)
    group.seasonData = seasonMetaData.json
    group.objects = TVEpisodes(seriesID, seasonID)
    ' watch for button presses
    group.observeField("episodeSelected", m.port)
    group.observeField("quickPlayNode", m.port)
    ' finished building SeasonDetails view
    stopLoadingSpinner()
    return group
end function

function CreateItemGrid(libraryItem as object) as dynamic
    ' validate libraryItem
    if not isValid(libraryItem) then return invalid

    group = CreateObject("roSGNode", "ItemGrid")
    group.parentItem = libraryItem
    group.optionsAvailable = true
    group.observeField("selectedItem", m.port)
    return group
end function

function CreateMovieLibraryView(libraryItem as object) as dynamic
    ' validate libraryItem
    if not isValid(libraryItem) then return invalid

    group = CreateObject("roSGNode", "MovieLibraryView")
    group.parentItem = libraryItem
    group.optionsAvailable = true
    group.observeField("selectedItem", m.port)
    return group
end function

function CreateMusicLibraryView(libraryItem as object) as dynamic
    ' validate libraryItem
    if not isValid(libraryItem) then return invalid

    group = CreateObject("roSGNode", "MusicLibraryView")
    group.parentItem = libraryItem
    group.optionsAvailable = true
    group.observeField("selectedItem", m.port)
    return group
end function

function CreateSearchPage()
    ' Search + Results Page
    group = CreateObject("roSGNode", "searchResults")
    options = group.findNode("searchSelect")
    options.observeField("itemSelected", m.port)

    return group
end function

function CreateVideoPlayerGroup(video_id as string, mediaSourceId = invalid as dynamic, audio_stream_idx = 1 as integer, forceTranscoding = false as boolean, showIntro = true as boolean, allowResumeDialog = true as boolean)
    ' validate video_id
    if not isValid(video_id) or video_id = "" then return invalid

    startMediaLoadingSpinner()
    ' Video is Playing
    video = VideoPlayer(video_id, mediaSourceId, audio_stream_idx, defaultSubtitleTrackFromVid(video_id), forceTranscoding, showIntro, allowResumeDialog)

    if video = invalid then return invalid

    video.allowCaptions = true

    if video.errorMsg = "introaborted" then return video
    video.observeField("selectSubtitlePressed", m.port)
    video.observeField("selectPlaybackInfoPressed", m.port)
    video.observeField("state", m.port)
    stopLoadingSpinner()
    return video
end function

function CreatePersonView(personData as object) as dynamic
    ' validate personData node
    if not isValid(personData) or not isValid(personData.id) then return invalid

    startLoadingSpinner()
    ' get person meta data
    personMetaData = ItemMetaData(personData.id)
    ' validate season meta data
    if not isValid(personMetaData)
        stopLoadingSpinner()
        return invalid
    end if
    ' start building Person View
    person = CreateObject("roSGNode", "PersonDetails")
    ' push scene asap (to prevent extra button presses when retriving series/movie info)
    m.global.SceneManager.callFunc("pushScene", person)
    person.itemContent = personMetaData
    person.setFocus(true)
    ' watch for button presses
    person.observeField("selectedItem", m.port)
    person.findNode("favorite-button").observeField("buttonSelected", m.port)
    ' finished building Person View
    stopLoadingSpinner()
    return person
end function

sub UpdateSavedServerList()
    server = m.global.session.server.url
    username = get_setting("username")
    password = get_setting("password")

    if server = invalid or username = invalid or password = invalid
        return
    end if

    server = LCase(server)'Saved server data is always lowercase

    saved = get_setting("saved_servers")
    if isValid(saved)
        savedServers = ParseJson(saved)
        if isValid(savedServers.serverList) and savedServers.serverList.Count() > 0
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

'Opens dialog asking user if they want to resume video or start playback over only on the home screen
sub playbackOptionDialog(time as longinteger, meta as object)

    resumeData = [
        tr("Resume playing at ") + ticksToHuman(time) + ".",
        tr("Start over from the beginning.")
    ]

    group = m.global.sceneManager.callFunc("getActiveScene")

    if LCase(group.subtype()) = "home"
        if LCase(meta.type) = "episode"
            resumeData.push(tr("Go to series"))
            resumeData.push(tr("Go to season"))
            resumeData.push(tr("Go to episode"))
        end if
    end if

    m.global.sceneManager.callFunc("optionDialog", tr("Playback Options"), [], resumeData)
end sub
