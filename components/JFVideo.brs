sub init()
    m.playbackTimer = m.top.findNode("playbackTimer")
    m.bufferCheckTimer = m.top.findNode("bufferCheckTimer")
    m.top.observeField("state", "onState")
    m.top.observeField("position", "onPositionChanged")
    m.top.trickPlayBar.observeField("visible", "onTrickPlayBarVisibilityChange")
    m.playbackTimer.observeField("fire", "ReportPlayback")
    m.bufferPercentage = 0 ' Track whether content is being loaded
    m.playReported = false
    m.top.transcodeReasons = []
    m.bufferCheckTimer.duration = 30

    if get_user_setting("ui.design.hideclock") = "true"
        clockNode = findNodeBySubtype(m.top, "clock")
        if clockNode[0] <> invalid then clockNode[0].parent.removeChild(clockNode[0].node)
    end if

    ' Skip Intro Button
    m.skipIntroButton = m.top.findNode("skipIntro")
    m.skipIntroButton.text = tr("Skip Intro")
    m.introCompleted = false
    m.showskipIntroButtonAnimation = m.top.findNode("showskipIntroButton")
    m.hideskipIntroButtonAnimation = m.top.findNode("hideskipIntroButton")
    m.moveUpskipIntroButtonAnimation = m.top.findNode("moveUpskipIntroButton")
    m.moveDownskipIntroButtonAnimation = m.top.findNode("moveDownskipIntroButton")
end sub

'
' Checks if we have valid skip intro param data
function haveSkipIntroParams() as boolean

    ' Intro data is invalid, skip
    if not isValid(m.top.skipIntroParams?.Valid)
        return false
    end if

    ' Returned intro data is not valid, return
    if not m.top.skipIntroParams.Valid
        return false
    end if

    return true
end function

'
' Handles showing / hiding the skip intro button
sub handleSkipIntro()
    ' We've already shown the intro, return
    if m.introCompleted then return

    ' We don't have valid data, return
    if not haveSkipIntroParams() then return

    ' Check if it's time to hide the skip prompt
    if m.top.position >= m.top.skipIntroParams.HideSkipPromptAt
        if skipIntroButtonVisible()
            hideSkipIntro()
        end if
        return
    end if

    ' Check if it's time to show the skip prompt
    if m.top.position >= m.top.skipIntroParams.ShowSkipPromptAt
        if not skipIntroButtonVisible()
            showSkipIntro()
        end if
        return
    end if
end sub

'
' When Trick Playbar Visibility changes
sub onTrickPlayBarVisibilityChange()
    ' Skip Intro button isn't visible, return
    if not skipIntroButtonVisible() then return

    ' Trick Playbar is visible, move the skip intro button up and fade it out
    if m.top.trickPlayBar.visible
        m.moveUpskipIntroButtonAnimation.control = "start"

        m.skipIntroButton.setFocus(false)
        m.top.setFocus(true)

        return
    end if

    ' Trick Playbar is not visible, move the skip intro button down and fade it in
    m.moveDownskipIntroButtonAnimation.control = "start"
    m.skipIntroButton.setFocus(true)

end sub

'
' When Video Player state changes
sub onPositionChanged()
    ' Check if content is episode
    if m.top.content.contenttype = 4
        handleSkipIntro()
    end if
end sub

'
' Returns if skip intro button is currently visible
function skipIntroButtonVisible() as boolean
    return m.skipIntroButton.opacity > 0
end function

'
' Runs skip intro button animation and sets focus to button
sub showSkipIntro()
    m.showskipIntroButtonAnimation.control = "start"
    m.skipIntroButton.setFocus(true)
end sub

'
' Runs hide intro button animation and sets focus back to video
sub hideSkipIntro()
    m.top.trickPlayBar.unobserveField("visible")
    m.hideskipIntroButtonAnimation.control = "start"
    m.introCompleted = true
    m.skipIntroButton.setFocus(false)
    m.top.setFocus(true)
end sub

'
' When Video Player state changes
sub onState(msg)
    ' When buffering, start timer to monitor buffering process
    if m.top.state = "buffering" and m.bufferCheckTimer <> invalid

        ' start timer
        m.bufferCheckTimer.control = "start"
        m.bufferCheckTimer.ObserveField("fire", "bufferCheck")
    else if m.top.state = "error"
        if not m.playReported and m.top.transcodeAvailable
            m.top.retryWithTranscoding = true ' If playback was not reported, retry with transcoding
        else
            ' If an error was encountered, Display dialog
            dialog = createObject("roSGNode", "Dialog")
            dialog.title = tr("Error During Playback")
            dialog.buttons = [tr("OK")]
            dialog.message = tr("An error was encountered while playing this item.")
            dialog.observeField("buttonSelected", "dialogClosed")
            m.top.getScene().dialog = dialog
        end if

        ' Stop playback and exit player
        m.top.control = "stop"
        m.top.backPressed = true
    else if m.top.state = "playing"
        if m.playReported = false
            ReportPlayback("start")
            m.playReported = true
        else
            m.playbackTimer.control = "start"
            ReportPlayback()
        end if
    else if m.top.state = "paused"
        m.playbackTimer.control = "stop"
        ReportPlayback()
    else if m.top.state = "stopped"
        m.playbackTimer.control = "stop"
        ReportPlayback("stop")
        m.playReported = false
    end if

end sub

'
' Report playback to server
sub ReportPlayback(state = "update" as string)

    if m.top.position = invalid then return

    params = {
        "ItemId": m.top.id,
        "PlaySessionId": m.top.PlaySessionId,
        "PositionTicks": int(m.top.position) * 10000000&, 'Ensure a LongInteger is used
        "IsPaused": (m.top.state = "paused")
    }
    if m.top.content.live
        params.append({
            "MediaSourceId": m.top.transcodeParams.MediaSourceId,
            "LiveStreamId": m.top.transcodeParams.LiveStreamId
        })
        m.bufferCheckTimer.duration = 30
    end if

    ' Report playstate via worker task
    playstateTask = m.global.playstateTask
    playstateTask.setFields({ status: state, params: params })
    playstateTask.control = "RUN"
end sub

'
' Check the the buffering has not hung
sub bufferCheck(msg)

    if m.top.state <> "buffering"
        ' If video is not buffering, stop timer
        m.bufferCheckTimer.control = "stop"
        m.bufferCheckTimer.unobserveField("fire")
        return
    end if
    if m.top.bufferingStatus <> invalid

        ' Check that the buffering percentage is increasing
        if m.top.bufferingStatus["percentage"] > m.bufferPercentage
            m.bufferPercentage = m.top.bufferingStatus["percentage"]
        else if m.top.content.live = true
            m.top.callFunc("refresh")
        else
            ' If buffering has stopped Display dialog
            dialog = createObject("roSGNode", "Dialog")
            dialog.title = tr("Error Retrieving Content")
            dialog.buttons = [tr("OK")]
            dialog.message = tr("There was an error retrieving the data for this item from the server.")
            dialog.observeField("buttonSelected", "dialogClosed")
            m.top.getScene().dialog = dialog

            ' Stop playback and exit player
            m.top.control = "stop"
            m.top.backPressed = true
        end if
    end if

end sub

'
' Clean up on Dialog Closed
sub dialogClosed(msg)
    sourceNode = msg.getRoSGNode()
    sourceNode.unobserveField("buttonSelected")
    sourceNode.close = true
end sub



function onKeyEvent(key as string, press as boolean) as boolean
    if key = "OK"
        if not m.top.trickPlayBar.visible
            if m.skipIntroButton.hasFocus()
                m.top.seek = m.top.skipIntroParams.IntroEnd
                hideSkipIntro()
                return true
            end if
        end if
    end if

    if not press then return false

    if m.top.Subtitles.count() and key = "down"
        m.top.selectSubtitlePressed = true
        return true
    end if

    return false
end function
