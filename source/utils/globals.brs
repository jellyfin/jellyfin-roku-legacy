' Set global constants
sub setConstants()
    globals = m.screen.getGlobalNode()

    ' Set Global Constants
    globals.addFields({
        constants: {

            poster_bg_pallet: ["#00455c", "#44bae1", "#00a4db", "#1c4c5c", "#007ea8"],

            colors: {
                button: "#006fab",
                blue: "#00a4dcFF"
            },

            icons: {
                ascending_black: "pkg:/images/icons/up_black.png",
                ascending_white: "pkg:/images/icons/up_white.png",
                descending_black: "pkg:/images/icons/down_black.png",
                descending_white: "pkg:/images/icons/down_white.png",
                check_black: "pkg:/images/icons/check_black.png",
                check_white: "pkg:/images/icons/check_white.png"
            }
        }
    })
end sub

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
