' Set global constants
sub setConstants()
    globals = m.screen.getGlobalNode()

    ' Set Global Constants
    globals.addFields({
        constants: {

            jellyfin_server: "jellyfin server",

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
    lastRunVersion = get_setting("LastRunVersion")
    m.global.addFields({
        app: {
            id: appInfo.GetID(),
            isDev: appInfo.IsDev(),
            version: appInfo.GetVersion(),
            lastRunVersion: lastRunVersion
        }
    })
end sub

' Save information from roDeviceInfo to m.global.device
sub SaveDeviceToGlobal()
    deviceInfo = CreateObject("roDeviceInfo")

    ' remove special characters
    regex = CreateObject("roRegex", "[^a-zA-Z0-9\ \-\_]", "")
    filteredFriendly = regex.ReplaceAll(deviceInfo.getFriendlyName(), "")
    ' parse out serial
    displayName = deviceInfo.getModelDisplayName()
    deviceSerial = Mid(filteredFriendly, len(displayName) + 4)
    ' determine max playback resolution
    ' https://developer.roku.com/en-ca/docs/references/brightscript/interfaces/ifdeviceinfo.md#getvideomode-as-string
    videoMode = deviceInfo.GetVideoMode()
    iPos = Instr(1, videoMode, "i")
    pPos = Instr(1, videoMode, "p")
    videoHeight = invalid
    videoWidth = invalid
    refreshRate = "0"
    bitDepth = 8
    extraData = invalid
    heightToWidth = {
        "480": "720",
        "576": "720",
        "720": "1280",
        "1080": "1920",
        "2160": "3840",
        "4320": "7680"

    }
    if iPos > 0 and pPos = 0
        ' videMode = 000i
        videoHeight = mid(videoMode, 1, iPos - 1)
        ' save refresh rate
        if Len(videoMode) > iPos
            refreshRate = mid(videoMode, iPos + 1, 2)
        end if
        ' save whats left of string
        if Len(videoMode) > iPos + 2
            extraData = mid(videoMode, iPos + 3)
        end if
    else if iPos = 0 and pPos > 0
        ' videMode = 000p
        videoHeight = mid(videoMode, 1, pPos - 1)
        ' save refresh rate
        if Len(videoMode) > pPos
            refreshRate = mid(videoMode, pPos + 1, 2)
        end if
        ' save whats left of string
        if Len(videoMode) > pPos + 2
            extraData = mid(videoMode, pPos + 3)
        end if
    else
        'i and p not present in videoMode
        print "ERROR parsing deviceInfo.GetVideoMode()"
    end if
    videoWidth = heightToWidth[videoHeight]
    if videoHeight = "2160" and extraData = "b10"
        bitDepth = 10
    else if videoHeight = "4320"
        bitDepth = 12
    end if

    m.global.addFields({
        device: {
            id: deviceInfo.getChannelClientID(),
            uuid: deviceInfo.GetRandomUUID(),
            name: displayName,
            friendlyName: filteredFriendly,
            serverDeviceName: deviceInfo.getChannelClientID(),
            model: deviceInfo.GetModel(),
            modelType: deviceInfo.GetModelType(),
            modelDetails: deviceInfo.GetModelDetails(),
            serial: deviceSerial,
            osVersion: deviceInfo.GetOSVersion(),
            locale: deviceInfo.GetCurrentLocale(),
            clockFormat: deviceInfo.GetClockFormat(),
            isAudioGuideEnabled: deviceInfo.IsAudioGuideEnabled(),
            hasVoiceRemote: deviceInfo.HasFeature("voice_remote"),

            displayType: deviceInfo.GetDisplayType(),
            displayMode: deviceInfo.GetDisplayMode(),
            videoMode: videoMode,
            videoHeight: videoHeight,
            videoWidth: videoWidth,
            videoRefresh: StrToI(refreshRate),
            videoBitDepth: bitDepth
        }
    })
end sub
