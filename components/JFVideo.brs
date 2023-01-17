sub init()
    m.playbackTimer = m.top.findNode("playbackTimer")
    m.bufferCheckTimer = m.top.findNode("bufferCheckTimer")
    m.top.observeField("state", "onState")
    m.top.observeField("content", "onContentChange")
    m.top.observeField("position", "onPositionChange")

    m.playbackTimer.observeField("fire", "ReportPlayback")
    m.bufferPercentage = 0 ' Track whether content is being loaded
    m.playReported = false
    m.top.transcodeReasons = []
    m.bufferCheckTimer.duration = 30

    if get_user_setting("ui.design.hideclock") = "true"
        clockNode = findNodeBySubtype(m.top, "clock")
        if clockNode[0] <> invalid then clockNode[0].parent.removeChild(clockNode[0].node)
    end if

    'Play Next Episode button
    m.nextEpisodeButton = m.top.findNode("nextEpisode")
    m.nextEpisodeButton.text = tr("Next Episode")
    m.nextEpisodeButton.setFocus(false)

    m.showNextEpisodeButtonAnimation = m.top.findNode("showNextEpisodeButton")
    m.hideNextEpisodeButtonAnimation = m.top.findNode("hideNextEpisodeButton")

    m.checkedForNextEpisode = false
    m.hasNextEpisode = false
    m.getNextEpisodeTask = createObject("roSGNode", "GetNextEpisodeTask")
    m.getNextEpisodeTask.observeField("nextEpisodeData", "onNextEpisodeDataLoaded")

    'Skip Intro Button
    m.skipIntroButton = m.top.findNode("skipIntro")
    m.skipIntroButton.text = tr("Skip Intro")
    m.skipIntroButton.visible = false
    m.skipIntroButton.setFocus(false)

    m.showSkipIntroButtonAnimation = m.top.findNode("showSkipIntroButton")
    m.hideSkipIntroButtonAnimation = m.top.findNode("hideSkipIntroButton")

    m.checkedForIntro = false
    m.hasIntro = false
    m.introPassed = false
    m.getIntroInfoTask = createObject("roSGNode", "GetIntroInfoTask")
    m.getIntroInfoTask.observeField("introData", "onIntroDataLoaded")
end sub

' Event handler for when video content field changes
sub onContentChange()
    if not isValid(m.top.content) then return

    ' If video content type is not episode, clear the hasNextEpisode flag
    if m.top.content.contenttype <> 4
        m.hasNextEpisode = false
    end if
end sub

sub onNextEpisodeDataLoaded()
    m.checkedForNextEpisode = true
    m.hasNextEpisode = m.getNextEpisodeTask.nextEpisodeData.Items.count() = 2
end sub

sub onIntroDataLoaded()
    m.checkedForIntro = true

    if m.getIntroInfoTask.introData.Valid
        m.hasIntro = true
        m.introPromptStartTime = m.getIntroInfoTask.introData.ShowSkipPromptAt
        m.introPromptEndTime = m.getIntroInfoTask.introData.HideSkipPromptAt
        m.introSkipTime = m.getIntroInfoTask.introData.IntroEnd
    end if
end sub

'
' Runs Next Episode button animation and sets focus to button
sub showNextEpisodeButton()
    if not m.nextEpisodeButton.visible
        m.showNextEpisodeButtonAnimation.control = "start"
        m.nextEpisodeButton.setFocus(true)
        m.nextEpisodeButton.visible = true
    end if
end sub

'
'Update count down text
sub updateCount()
    m.nextEpisodeButton.text = tr("Next Episode") + " " + Int(m.top.runTime - m.top.position).toStr()
end sub

'
' Runs hide Next Episode button animation and sets focus back to video
sub hideNextEpisodeButton()
    m.hideNextEpisodeButtonAnimation.control = "start"
    m.nextEpisodeButton.setFocus(false)
    m.top.setFocus(true)
end sub

' Checks if we need to display the Next Episode button
sub checkTimeToDisplayNextEpisode()
    if int(m.top.position) >= (m.top.runTime - 30)
        showNextEpisodeButton()
        updateCount()
        return
    end if

    if m.nextEpisodeButton.visible or m.nextEpisodeButton.hasFocus()
        m.nextEpisodeButton.visible = false
        m.nextEpisodeButton.setFocus(false)
    end if
end sub

' When Video Player position changes
sub onPositionChange()
    ' Check if dialog is open
    m.dialog = m.top.getScene().findNode("dialogBackground")
    if not isValid(m.dialog)
        if m.hasIntro and not m.introPassed
            checkSkipIntroDisplay()
        end if
        if m.hasNextEpisode
            checkTimeToDisplayNextEpisode()
        end if
    end if
end sub

' Show the Skip Intro button
sub showSkipIntroButton()
    if not m.skipIntroButton.visible
        m.showSkipIntroButtonAnimation.control = "start"
        m.skipIntroButton.setFocus(true)
        m.skipIntroButton.visible = true
    end if
end sub

' Hide the Skip Intro button
sub hideSkipIntroButton()
    if m.skipIntroButton.visible and m.hideSkipIntroButtonAnimation.state = "stopped"
        m.hideSkipIntroButtonAnimation.control = "start"
        m.hideSkipIntroButtonAnimation.observeField("state", "hideSkipIntroButtonFinished")
        m.skipIntroButton.setFocus(false)
        m.introPassed = true
        m.top.setFocus(true)
    end if
end sub

' Fully hide the Skip Intro button
sub hideSkipIntroButtonFinished()
    if m.hideSkipIntroButtonAnimation.state = "stopped"
        m.skipIntroButton.visible = false
        m.hideSkipIntroButtonAnimation.unobserveField("state")
    end if
end sub

' Checks if we should display the Skip Intro button
sub checkSkipIntroDisplay()
    curPos = int(m.top.position)
    if curPos >= m.introPromptStartTime and curPos <= m.introPromptEndTime and not m.skipIntroButton.visible
        showSkipIntroButton()
    else if curPos > m.introPromptEndTime and m.skipIntroButton.visible
        hideSkipIntroButton()
        m.introPassed = true
    end if
end sub

'
' When Video Player state changes
sub onState(msg)
    ' Check if there is an intro to skip when the state is buffering or playing
    if m.top.state = "buffering" or m.top.state = "playing"
        if isValid(m.top.videoID)
            if m.top.videoID <> "" and not m.checkedForIntro and m.top.content.contenttype = 4
                m.getIntroInfoTask.videoID = m.top.videoID
                m.getIntroInfoTask.control = "RUN"
            end if
        end if
    end if

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

        ' Check if next episde is available
        if isValid(m.top.showID)
            if m.top.showID <> "" and not m.checkedForNextEpisode and m.top.content.contenttype = 4
                m.getNextEpisodeTask.showID = m.top.showID
                m.getNextEpisodeTask.videoID = m.top.id
                m.getNextEpisodeTask.control = "RUN"
            end if
        end if

        if m.playReported = false
            ReportPlayback("start")
            m.playReported = true
        else
            ReportPlayback()
        end if
        m.playbackTimer.control = "start"
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

    if key = "OK" and m.nextEpisodeButton.hasfocus() and not m.top.trickPlayBar.visible
        m.top.state = "finished"
        hideNextEpisodeButton()
        return true
    else
        'Hide Next Episode Button
        if m.nextEpisodeButton.visible or m.nextEpisodeButton.hasFocus()
            m.nextEpisodeButton.visible = false
            m.nextEpisodeButton.setFocus(false)
            m.top.setFocus(true)
        end if
    end if

    if key = "OK" and m.skipIntroButton.hasfocus() and not m.top.trickPlayBar.visible
        m.top.seek = m.introSkipTime
        hideSkipIntroButton()
        return true
    else
        'Hide Skip Intro Button
        if m.skipIntroButton.visible or m.skipIntroButton.hasFocus()
            m.skipIntroButton.visible = false
            m.skipIntroButton.setFocus(false)
            m.top.setFocus(true)
        end if
    end if

    if not press then return false

    if key = "down"
        m.top.selectSubtitlePressed = true
        return true
    else if key = "up"
        m.top.selectPlaybackInfoPressed = true
        return true
    else if key = "OK"
        ' OK will play/pause depending on current state
        ' return false to allow selection during seeking
        if m.top.state = "paused"
            m.top.control = "resume"
            return false
        else if m.top.state = "playing"
            m.top.control = "pause"
            return false
        end if
    end if

    return false
end function
