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

' Save information about the user's current session to m.global.session
sub SaveSessionToGlobal()
    userConfig = AboutMe()
    userConfig.Append({ "authToken": get_user_setting("token") })

    myServerInfo = ServerInfo()
    myServerInfo.Append({ "name": myServerInfo.ServerName })
    ' grab server url from registry
    serverURL = get_setting("server")
    myServerInfo.Append({ "url": serverURL })
    ' search server URL for https protocol
    isServerHTTPS = false
    if serverURL.left(8) = "https://" then isServerHTTPS = true
    myServerInfo.Append({ "isHTTPS": isServerHTTPS })

    if m.global.session = invalid
        m.global.addFields({
            session: {
                server: myServerInfo,
                user: userConfig
            }
        })
    else
        m.global.setFields({
            session: {
                server: myServerInfo,
                user: userConfig
            }
        })
    end if
    print "m.global.session.server = ", m.global.session.server
    print "m.global.session.user = ", m.global.session.user
end sub
