' Save information from roAppInfo to m.global.app
sub SaveAppToGlobal()
    appInfo = CreateObject("roAppInfo")
    m.global.addFields({
        app: {
            id: appInfo.GetID(),
            isDev: appInfo.IsDev(),
            version: appInfo.GetVersion()
        }
    })
end sub

' Save information from roDeviceInfo to m.global.device
sub SaveDeviceToGlobal()
    deviceInfo = CreateObject("roDeviceInfo")
    ' remove special characters
    regex = CreateObject("roRegex", "[^a-zA-Z0-9\ \-\_]", "")
    filteredFriendly = regex.ReplaceAll(deviceInfo.getFriendlyName(), "")
    m.global.addFields({
        device: {
            id: deviceInfo.getChannelClientID(),
            uuid: deviceInfo.GetRandomUUID(),
            name: deviceInfo.getModelDisplayName(),
            friendlyName: filteredFriendly,
            model: deviceInfo.GetModel(),
            modelType: deviceInfo.GetModelType(),
            osVersion: deviceInfo.GetOSVersion(),
            locale: deviceInfo.GetCurrentLocale(),
            clockFormat: deviceInfo.GetClockFormat(),
            isAudioGuideEnabled: deviceInfo.IsAudioGuideEnabled(),
            hasVoiceRemote: deviceInfo.HasFeature("voice_remote"),

            displayType: deviceInfo.GetDisplayType(),
            displayMode: deviceInfo.GetDisplayMode()
        }
    })
end sub

' Initialize global session
sub InitSession()
    m.global.addFields({
        session: {
            server: {},
            user: {}
        }
    })
end sub

' Empty all values inside global session array
sub WipeSession()
    UpdateSession("server")
    UpdateSession("user")
end sub

' Update one value from the global session array (m.global.session)
sub UpdateSession(key as string, value = {} as object)
    ' validate parameters
    if key = "" or (key <> "user" and key <> "server") or value = invalid
        print "Error in UpdateSession(): Invalid parameters provided"
        return
    end if
    ' make copy of global session array
    tmpSession = m.global.session
    ' update the temp session array
    tmpSession.AddReplace(key, value)
    ' use the temp session array to update the global node
    m.global.setFields({ session: tmpSession })
    print "m.global.session." + key + " = ", m.global.session[key]
end sub

' Add or update one value from the global server session array (m.global.session.server)
sub UpdateSessionServer(key as string, value as dynamic)
    ' validate parameters
    if key = "" or value = invalid then return
    ' make copy of global server session array
    tmpSessionServer = m.global.session.server
    ' update the temp server array
    tmpSessionServer[key] = value

    UpdateSession("server", tmpSessionServer)
end sub

' Use the saved server url to populate the global server session array (m.global.session.server)
sub PopulateSessionServer()
    ' validate server url
    if m.global.session.server.url = invalid or m.global.session.server.url = "" then return
    ' get server info using API
    myServerInfo = ServerInfo()
    ' validate data returned from API
    if myServerInfo.id = invalid then return
    ' make copy of global server session
    tmpSessionServer = m.global.session.server
    ' update the temp array
    tmpSessionServer.AddReplace("id", myServerInfo.Id)
    tmpSessionServer.AddReplace("name", myServerInfo.ServerName)
    tmpSessionServer.AddReplace("localURL", myServerInfo.LocalAddress)
    tmpSessionServer.AddReplace("os", myServerInfo.OperatingSystem)
    tmpSessionServer.AddReplace("startupWizardCompleted", myServerInfo.StartupWizardCompleted)
    tmpSessionServer.AddReplace("version", myServerInfo.Version)
    tmpSessionServer.AddReplace("hasError", myServerInfo.error)
    ' check urls for https
    isServerHTTPS = false
    if tmpSessionServer.url.left(8) = "https://" then isServerHTTPS = true
    tmpSessionServer.AddReplace("isHTTPS", isServerHTTPS)
    isLocalServerHTTPS = false
    if myServerInfo.LocalAddress <> invalid and myServerInfo.LocalAddress.left(8) = "https://" then isLocalServerHTTPS = true
    tmpSessionServer.AddReplace("isLocalHTTPS", isLocalServerHTTPS)
    ' update global server session using the temp array
    UpdateSession("server", tmpSessionServer)
end sub

' Add or update one value from the global user session array (m.global.session.user)
sub UpdateSessionUser(key as string, value as dynamic)
    ' validate parameters
    if key = "" or value = invalid then return
    ' make copy of global user session
    tmpSessionUser = m.global.session.user
    ' update the temp user array
    tmpSessionUser[key] = value
    ' update global user session using the temp array
    UpdateSession("user", tmpSessionUser)
end sub

' Update the global session after user is authenticated.
' Accepts a UserData.xml object from get_token() or an assocArray from AboutMe()
sub SessionLogin(userData as object)
    ' validate parameters
    if userData = invalid or userData.id = invalid then return
    ' make copy of global user session array
    tmpSession = m.global.session
    if userData.json = invalid
        ' we were passed data from AboutMe
        myAuthToken = tmpSession.user.authToken
        tmpSession.AddReplace("user", userData)
        tmpSession.user.AddReplace("authToken", myAuthToken)
    else
        ' we were passed data from a UserData object
        tmpSession.AddReplace("user", userData.json.User)
        tmpSession.user.AddReplace("authToken", userData.json.AccessToken)
    end if

    userSettings = RegistryReadAll(tmpSession.user.id)
    tmpSession.user.AddReplace("settings", userSettings)
    ' update global user session
    UpdateSession("user", tmpSession.user)
    print "m.global.session.user.settings = ", m.global.session.user.settings
    ' ensure registry is updated
    set_user_setting("username", tmpSession.user.name)
    set_user_setting("token", tmpSession.user.authToken)
end sub
