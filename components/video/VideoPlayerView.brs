sub init()
    currentItem = m.global.queueManager.callFunc("getCurrentItem")

    m.top.id = currentItem.id

    ' Load meta data
    m.LoadMetaDataTask = CreateObject("roSGNode", "LoadVideoContentTask")
    m.LoadMetaDataTask.itemId = currentItem.id
    m.LoadMetaDataTask.observeField("content", "onVideoContentLoaded")
    m.LoadMetaDataTask.control = "RUN"

    m.playbackTimer = m.top.findNode("playbackTimer")
    m.bufferCheckTimer = m.top.findNode("bufferCheckTimer")
    m.top.observeField("state", "onState")
    m.top.observeField("content", "onContentChange")

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
    m.getNextEpisodeTask = createObject("roSGNode", "GetNextEpisodeTask")
    m.getNextEpisodeTask.observeField("nextEpisodeData", "onNextEpisodeDataLoaded")

    m.top.retrievingBar.filledBarBlendColor = m.global.constants.colors.blue
    m.top.bufferingBar.filledBarBlendColor = m.global.constants.colors.blue
    m.top.trickPlayBar.filledBarBlendColor = m.global.constants.colors.blue
end sub

sub onVideoContentLoaded()
    m.LoadMetaDataTask.unobserveField("content")

    ' If we have nothing to play, return to previous screen
    if not isValid(m.LoadMetaDataTask.content)
        m.global.sceneManager.callFunc("popScene")
        return
    end if

    if not isValid(m.LoadMetaDataTask.content[0])
        m.global.sceneManager.callFunc("popScene")
        return
    end if

    if m.LoadMetaDataTask.content.count() = 0
        m.global.sceneManager.callFunc("popScene")
        return
    end if

    m.top.content = m.LoadMetaDataTask.content[0].content
    m.top.PlaySessionId = m.LoadMetaDataTask.content[0].PlaySessionId
    m.top.videoId = m.LoadMetaDataTask.content[0].id
    m.top.container = m.LoadMetaDataTask.content[0].container
    m.top.mediaSourceId = m.LoadMetaDataTask.content[0].mediaSourceId
    m.top.audioIndex = m.LoadMetaDataTask.content[0].audio_stream_idx

    m.top.setFocus(true)
    m.top.control = "play"
    m.top.getScene().findNode("overhang").visible = false
end sub

' Event handler for when video content field changes
sub onContentChange()
    if not isValid(m.top.content) then return

    m.top.observeField("position", "onPositionChanged")

    ' If video content type is not episode, remove position observer
    if m.top.content.contenttype <> 4
        m.top.unobserveField("position")
    end if
end sub

sub onNextEpisodeDataLoaded()
    m.checkedForNextEpisode = true

    m.top.observeField("position", "onPositionChanged")

    if m.getNextEpisodeTask.nextEpisodeData.Items.count() <> 2
        m.top.unobserveField("position")
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
    m.nextEpisodeButton.text = tr("Next Episode") + " " + Int(m.top.duration - m.top.position).toStr()
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
    if int(m.top.position) >= (m.top.duration - 30)
        showNextEpisodeButton()
        updateCount()
        return
    end if

    if m.nextEpisodeButton.visible or m.nextEpisodeButton.hasFocus()
        m.nextEpisodeButton.visible = false
        m.nextEpisodeButton.setFocus(false)
    end if
end sub

' When Video Player state changes
sub onPositionChanged()
    ' Check if dialog is open
    m.dialog = m.top.getScene().findNode("dialogBackground")
    if not isValid(m.dialog)
        checkTimeToDisplayNextEpisode()
    end if
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
        m.top.control = "stop"
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

    if key = "back"
        m.top.control = "stop"
    end if

    return false
end function
