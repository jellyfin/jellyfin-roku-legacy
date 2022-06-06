sub init()
    m.top.functionName = "PlaystateUpdate"
end sub

sub PlaystateUpdate()
    if m.top.status = "start"
        url = "Sessions/Playing"
    else if m.top.status = "stop"
        url = "Sessions/Playing/Stopped"
    else if m.top.status = "update"
        url = "Sessions/Playing/Progress"
    else
        ' Unknown State
        return
    end if
    params = PlaystateDefaults(m.top.params)
    resp = APIRequest(url)
    postJson(resp, params)
end sub

function PlaystateDefaults(params = {} as object)
    new_params = {
        '"CanSeek": false
        '"Item": "{}", ' TODO!
        '"NowPlayingQueue": "[]", ' TODO!
        '"PlaylistItemId": "",
        '"ItemId": id,
        '"SessionId": "", ' TODO!
        '"MediaSourceId": id,
        '"AudioStreamIndex": 1,
        '"SubtitleStreamIndex": 0,
        "IsPaused": false,
        '"IsMuted": false,
        "PositionTicks": 0,
        '"PlaybackStartTimeTicks": 0,
        '"VolumeLevel": 100,
        '"Brightness": 100,
        '"AspectRatio": "16x9",
        '"PlayMethod": "DirectStream"
        '"LiveStreamId": "",
        '"PlaySessionId": "",
        '"RepeatMode": "RepeatNone"
    }

    paramsArray = params.items()
    for i = 0 to paramsArray.count() - 1
        item = paramsArray[i]
        new_params[item.key] = item.value
    end for
    return FormatJson(new_params)
end function
