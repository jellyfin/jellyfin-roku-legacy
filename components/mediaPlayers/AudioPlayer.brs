sub init()
    m.playReported = false
    m.top.observeField("state", "audioStateChanged")
end sub

' State Change Event Handler
sub audioStateChanged()
    currentState = LCase(m.top.state)

    reportedPlaybackState = "update"

    m.top.disableScreenSaver = (currentState = "playing")

    if currentState = "playing" and not m.playReported
        reportedPlaybackState = "start"
        m.playReported = true
    else if currentState = "stopped" or currentState = "finished"
        reportedPlaybackState = "stop"
        m.playReported = false
    end if

    ReportPlayback(reportedPlaybackState)
end sub

' Report playback to server
sub ReportPlayback(state as string)

    if not isValid(m.top.position) then return

    params = {
        "ItemId": m.global.queueManager.callFunc("getCurrentItem").id,
        "PlaySessionId": m.top.content.id,
        "PositionTicks": int(m.top.position) * 10000000&, 'Ensure a LongInteger is used
        "IsPaused": (LCase(m.top.state) = "paused")
    }

    ' Report playstate via global task
    playstateTask = m.global.playstateTask
    playstateTask.setFields({ status: state, params: params })
    playstateTask.control = "RUN"
end sub
