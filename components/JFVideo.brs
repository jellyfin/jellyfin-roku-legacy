sub init()
    m.playbackTimer = m.top.findNode("playbackTimer")
    m.bufferCheckTimer = m.top.findNode("bufferCheckTimer")
    m.suppressKey = false
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

    m.buttonGrp = m.top.findNode("buttons")
    m.buttonGrp.observeField("escape", "onButtonGroupEscaped")
    m.buttonGrp.visible = false

    'Play Next Episode button
    m.nextEpisodeButton = m.top.findNode("nextEpisode")
    m.nextEpisodeButton.text = tr("Next Episode")
    m.nextEpisodeButton.setFocus(false)
    m.nextEpisodeButton.visible = false
    m.nextupbuttonseconds = get_user_setting("playback.nextupbuttonseconds", "30")
    if isValid(m.nextupbuttonseconds)
        m.nextupbuttonseconds = val(m.nextupbuttonseconds)
    else
        m.nextupbuttonseconds = 30
    end if

    m.showNextEpisodeButtonAnimation = m.top.findNode("showNextEpisodeButton")
    m.hideNextEpisodeButtonAnimation = m.top.findNode("hideNextEpisodeButton")

    m.checkedForNextEpisode = false
    m.movieInfo = false
    m.guideLoaded = false

    m.getNextEpisodeTask = createObject("roSGNode", "GetNextEpisodeTask")
    m.getNextEpisodeTask.observeField("nextEpisodeData", "onNextEpisodeDataLoaded")

    m.getItemQueryTask = createObject("roSGNode", "GetItemQueryTask")

    m.extras = m.top.findNode("extrasGrid")
    m.extrasGrp = m.top.findnode("extrasContainer")
    m.extrasGrp.opacity = 0

    m.showGuideAnimation = m.top.findNode("showGuide")
    m.top.observeField("state", "onState")
    m.top.observeField("content", "onContentChange")
    m.top.observeField("allowCaptions", "onAllowCaptionsChange")

end sub

sub onAllowCaptionsChange()
    if not m.top.allowCaptions then return

    m.captionGroup = m.top.findNode("captionGroup")
    m.captionGroup.createchildren(9, "LayoutGroup")
    m.captionTask = createObject("roSGNode", "captionTask")
    m.captionTask.observeField("currentCaption", "updateCaption")
    m.captionTask.observeField("useThis", "checkCaptionMode")
    m.top.observeField("currentSubtitleTrack", "loadCaption")
    m.top.observeField("globalCaptionMode", "toggleCaption")
    if get_user_setting("playback.subs.custom") = "false"
        m.top.suppressCaptions = false
    else
        m.top.suppressCaptions = true
        toggleCaption()
    end if
end sub

sub loadCaption()
    if m.top.suppressCaptions
        m.captionTask.url = m.top.currentSubtitleTrack
    end if
end sub

sub toggleCaption()
    m.captionTask.playerState = m.top.state + m.top.globalCaptionMode
    if LCase(m.top.globalCaptionMode) = "on"
        m.captionTask.playerState = m.top.state + m.top.globalCaptionMode + "w"
        m.captionGroup.visible = true
    else
        m.captionGroup.visible = false
    end if
end sub

sub updateCaption ()
    m.captionGroup.removeChildrenIndex(m.captionGroup.getChildCount(), 0)
    m.captionGroup.appendChildren(m.captionTask.currentCaption)
end sub

' Event handler for when video content field changes
sub onContentChange()
    if not isValid(m.top.content) then return

    m.top.observeField("position", "onPositionChanged")

end sub

sub onNextEpisodeDataLoaded()
    if m.getNextEpisodeTask.nextEpisodeData.Items.count() = 2
        m.top.observeField("position", "onPositionChanged")
        m.checkedForNextEpisode = true
    else ' No Next episode found, remove position observer
        m.top.unobserveField("position")
        m.checkedForNextEpisode = true
    end if
end sub


'
' Runs Next Episode button animation and sets focus to button
sub showNextEpisodeButton()
    if m.global.userConfig.EnableNextEpisodeAutoPlay and not m.nextEpisodeButton.visible
        m.showNextEpisodeButtonAnimation.control = "start"
        m.nextEpisodeButton.setFocus(true)
        m.nextEpisodeButton.visible = true
    end if
end sub

'
'Update count down text
sub updateCount()
    nextEpisodeCountdown = Int(m.top.duration - m.top.position)
    if nextEpisodeCountdown < 0
        nextEpisodeCountdown = 0
    end if
    m.nextEpisodeButton.text = tr("Next Episode") + " " + nextEpisodeCountdown.toStr()
end sub


' Checks if we need to display the Next Episode button
sub checkTimeToDisplayNextEpisode()
    if m.top.content.contenttype <> 4 then return
    if m.nextupbuttonseconds = 0 then return

    if int(m.top.position) >= (m.top.duration - m.nextupbuttonseconds)
        showNextEpisodeButton()
        updateCount()
        return
    end if

end sub

' When Video Player state changes
sub onPositionChanged()
    if isValid(m.captionTask)
        m.captionTask.currentPos = Int(m.top.position * 1000)
    end if
    ' Check if dialog is open
    m.dialog = m.top.getScene().findNode("dialogBackground")
    if not isValid(m.dialog)
        checkTimeToDisplayNextEpisode()
    end if

    m.checkedForNextEpisode = false
    m.movieInfo = false
end sub

'
' When Video Player state changes
sub onState(msg)
    if isValid(m.captionTask)
        m.captionTask.playerState = m.top.state + m.top.globalCaptionMode
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
            dialog = createObject("roSGNode", "PlaybackDialog")
            dialog.title = tr("Error During Playback")
            dialog.buttons = [tr("OK")]
            dialog.message = tr("An error was encountered while playing this item.")
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
                ' if nextepisode data is invalid then get item data instead
                if m.getNextEpisodeTask.nextEpisodeData = invalid
                    m.getItemQueryTask.videoID = m.top.id
                    m.getItemQueryTask.control = "RUN"
                end if
                'remove Guide option
                m.buttonGrp.removeChild(m.top.findNode("guide"))
                setupButtons()
            end if
        end if

        ' Check if video is movie
        if m.top.content.contenttype = 1
            if m.top.videoID <> "" and not m.movieInfo and m.top.content.contenttype = 1
                m.getItemQueryTask.videoID = m.top.id
                m.getItemQueryTask.control = "RUN"
                'remove Guide option
                m.buttonGrp.removeChild(m.top.findNode("guide"))
                setupButtons()
            end if
        end if
        'check if video is Live TV Channel
        if m.top.content.live = true
            m.buttonGrp.removeChild(m.top.findNode("cast"))
            m.buttonGrp.removeChild(m.top.findNode("cc"))
            m.getItemQueryTask.live = "true"
            m.getItemQueryTask.videoID = m.top.id
            m.getItemQueryTask.control = "RUN"
            setupButtons()
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
            ' m.top.callFunc("refresh")
        else
            ' If buffering has stopped Display dialog
            dialog = createObject("roSGNode", "PlaybackDialog")
            dialog.title = tr("Error Retrieving Content")
            dialog.buttons = [tr("OK")]
            dialog.message = tr("There was an error retrieving the data for this item from the server.")
            m.top.getScene().dialog = dialog

            ' Stop playback and exit player
            m.top.control = "stop"
            m.top.backPressed = true
        end if
    end if

end sub

sub setinfo()
    'episode info
    if not m.getNextEpisodeTask.nextEpisodeData = invalid
        m.info = m.getNextEpisodeTask.nextEpisodeData.Items[0].Overview
        m.content = m.getNextEpisodeTask.nextEpisodeData.Items[0]
    else if not m.getItemQueryTask.getItemQueryData = invalid and not m.top.content.live = true 'movie info
        m.info = m.getItemQueryTask.getItemQueryData.Items.[0].Overview
        m.content = m.getItemQueryTask.getItemQueryData.Items.[0]
    else if m.getItemQueryTask.getItemQueryData.Items.Count() > 0 'Live TV Content
        if not m.getItemQueryTask.getItemQueryData.Items.[0].Overview = invalid
            m.info = m.getItemQueryTask.getItemQueryData.Items.[0].Overview
        else
            m.info = invalid
        end if
        m.content = m.getItemQueryTask.getItemQueryData.Items.[0]
    else
        m.info = invalid
    end if

    if m.info = invalid
        m.buttonGrp.removeChild(m.top.findNode("info"))
    end if

end sub

sub info()

    ' If buffering has stopped Display dialog
    m.buttonGrp.visible = false
    dialog = createObject("roSGNode", "PlaybackInfoDialog")
    if not m.info = invalid
        dialog.message = m.info
        dialog.title = tr("Program Information")
    else
        dialog.message = "A description for this stream is not available."
    end if
    m.top.getScene().dialog = dialog
    m.top.control = "pause"
end sub

'
' Clean up on Dialog Closed
sub dialogClosed(msg)
    sourceNode = msg.getRoSGNode()
    sourceNode.unobserveField("buttonSelected")
    sourceNode.close = true
    '
    ' if paused and diloge closed then play video
    if m.top.control = "pause"
        m.top.control = "resume"
    end if
    m.top.setFocus(true)
end sub

sub Subtitles()
    m.top.selectSubtitlePressed = true
    m.buttonGrp.visible = false
    m.top.setFocus(true)
end sub

sub PlaybackInfo()
    m.buttonGrp.visible = false
    m.top.control = "pause"
    dialog = createObject("rosgnode", "PlaybackInfoDialog")
    dialog.title = tr("Stream Information")
    for i = 0 to m.top.playbackInfo.count() - 1
        dialog.message = dialog.message + m.top.playbackInfo[i] + chr(10)
    end for
    m.top.getScene().dialog = dialog

end sub

sub onButtonGroupEscaped()
    key = m.buttonGrp.escape
    if key = "up"
        m.buttonGrp.setFocus(false)
        m.buttonGrp.visible = false
    end if
    m.top.setFocus(true)
end sub

' Setup playback buttons, default to Play button selected
sub setupButtons()
    m.buttonGrp.visible = false
    m.buttonGrp = m.top.findNode("buttons")
    m.buttonCount = m.buttonGrp.getChildCount()
    m.top.observeField("selectedButtonIndex", "onButtonSelectedChange")
end sub

' Event handler when user selected a different playback button
sub onButtonSelectedChange()
    ' Change previously selected button back to default image
    previousSelectedButton = m.buttonGrp.getChild(m.previouslySelectedButtonIndex)
    previousSelectedButton.focus = false
    ' Change selected button image to selected image
    selectedButton = m.buttonGrp.getChild(m.top.selectedButtonIndex)
    selectedButton.focus = true
end sub

sub showTVGuide()
    m.tvGuide = createObject("roSGNode", "Schedule")
    m.tvGuide.removeChild(m.tvGuide.findNode("rec"))
    m.tvGuide.removeChild(m.tvGuide.findNode("detailsPane"))
    m.tvGuide.observeField("watchChannel", "onChannelSelected")
    m.tvGuide.visible = true
    m.tvGuide.setFocus(true)
    m.tvGuide.translation = "[0, 200]"
    m.tvGuide.lastFocus = "videoPlayer"
    m.top.appendChild(m.tvGuide)
    m.buttonGrp.setFocus(false)
    m.top.setFocus(false)
    m.buttonGrp.visible = false
    m.showGuideAnimation.control = "start"
    m.top.enableTrickPlay = false
    m.guideLoaded = true
end sub

sub onChannelSelected(msg)
    node = msg.getRoSGNode()
    m.top.lastFocus = lastFocusedChild(node)
    if node.watchChannel <> invalid
        m.top.selectedItem = node.watchChannel.id
        m.top.control = "stop"
        m.global.sceneManager.callfunc("clearPreviousScene")
    end if
    'remove guide from view while new channel is loading
    m.top.removeChild(m.tvGuide)
    m.tvGuide.setFocus(false)
    m.top.getScene().findNode("overhang").visible = false
end sub



function onKeyEvent(key as string, press as boolean) as boolean
    if m.suppressKey
        ' we need to listen to the down lift in order to hide the buttons bc the press is in ButtonGrp
        ' but we have to ignore the down lift so we dont show buttons when we close the slider with down
        m.suppressKey = false
        return true
    end if

    if key = "OK" and m.nextEpisodeButton.isinfocuschain() and m.top.state = "playing"
        m.top.control = "stop"
        m.top.state = "finished"
        m.nextEpisodeButton.visible = false
        return true
    else if key = "OK" and m.top.state = "playing"
        'Hide Next Episode Button
        m.nextEpisodeButton.visible = false
        m.nextEpisodeButton.setFocus(false)
    end if

    if key = "down"
        if press and m.nextEpisodeButton.visible = false
            if m.buttonGrp.isinFocusChain()
                m.buttonGrp.setFocus(false)
                m.buttonGrp.visible = false
                m.top.setFocus(true)
                return true
            else if m.extras.hasFocus()
                m.suppressKey = true
                closeExtrasSlider()
                return true
            end if
        else
            if m.top.state = "playing" and m.nextEpisodeButton.visible = false
                toggleButtonGrpVisible()
                return true
            end if
        end if
    end if

    if key = "back"
        if press
            if m.extras.hasFocus()
                closeExtrasSlider()
                return true
            else if m.buttonGrp.isInFocusChain()
                m.buttonGrp.visible = false
                m.buttonGrp.setFocus(false)
                m.top.setFocus(true)
                return true
            else if isValid(m.tvGuide) and m.tvGuide.isInFocusChain()
                m.tvGuide.setFocus(false)
                m.tvGuide.lastFocus = "videoPlayer"
                m.tvGuide.visible = false
                m.buttonGrp.setFocus(false)
                m.buttonGrp.visible = false
                m.top.enableTrickPlay = true
                m.top.setFocus(true)
                return true
            end if
        else
            if not m.buttonGrp.visible
                m.top.control = "resume"
                m.top.setFocus(true)
                return true
            end if
        end if
    end if


    if m.buttonGrp.visible
        if key = "OK"
            if press
                selectedButton = m.buttonGrp.getChild(m.top.selectedButtonIndex)
                selectedButton.selected = not selectedButton.selected
                if selectedButton.id = "guide"
                    showTVGuide()
                    return true
                end if
                if selectedButton.id = "cc"
                    m.top.selectSubtitlePressed = true
                    m.buttonGrp.visible = false
                    m.top.setFocus(true)
                end if
                if selectedButton.id = "playbackInfo"
                    PlaybackInfo()
                    m.top.control = "pause"
                end if
                if selectedButton.id = "info"
                    info()
                    m.top.control = "pause"
                    'return true
                end if
                if selectedButton.id = "cast"
                    m.top.control = "pause"
                    m.extrasGrp.opacity = 1
                    m.extras.setFocus(true)
                    m.top.findNode("VertSlider").reverse = false
                    m.top.findNode("extrasFader").reverse = false
                    m.top.findNode("pplAnime").control = "start"
                    m.buttonGrp.visible = false
                    m.top.enableTrickPlay = false
                    return true
                end if
            end if
        end if

        if key = "left" and press
            if m.top.selectedButtonIndex > 0
                m.previouslySelectedButtonIndex = m.top.selectedButtonIndex
                m.top.selectedButtonIndex = m.top.selectedButtonIndex - 1
            end if
            return true
        else if key = "right"
            m.previouslySelectedButtonIndex = m.top.selectedButtonIndex
            if m.top.selectedButtonIndex < m.buttonCount - 1 then m.top.selectedButtonIndex = m.top.selectedButtonIndex + 1
            return true
        end if
        return false
    end if

    if not press then return false

    if key = "OK"
        ' OK will play/pause depending on current state
        ' return false to allow selection during seeking
        if m.top.state = "paused"
            m.top.trickPlayBar.visible = false
            m.top.control = "resume"
            m.top.setFocus(true)
            return false
        else if m.top.state = "playing"
            m.top.trickPlayBar.visible = true
            m.top.control = "pause"
            m.top.setFocus(true)
            return false
        end if
    end if


    return false
end function

sub closeExtrasSlider()
    m.extras.setFocus(false)
    m.top.findNode("VertSlider").reverse = true
    m.top.findNode("extrasFader").reverse = true
    m.top.findNode("pplAnime").control = "start"
    m.top.setFocus(true)
    m.top.control = "resume"
    m.extrasGrp.opacity = 0
    m.top.enableTrickPlay = true
end sub

sub toggleButtonGrpVisible()
    setinfo()
    if not m.top?.content.live = true
        if m.content.People.count() < 1
            m.buttonGrp.removeChild(m.top.findNode("cast"))
        end if
    else
        m.buttonGrp.removeChild(m.top.findNode("cast"))
    end if
    if not m.top?.content.live = true
        if m.content.HasSubtitles = invalid
            m.buttonGrp.removeChild(m.top.findNode("cc"))
        end if
    else
        m.buttonGrp.removeChild(m.top.findNode("cc"))
    end if
    if m.buttonGrp.visible
        m.buttonGrp.setFocus(false)
        m.buttonGrp.visible = false
        m.top.setFocus(true)
    else
        'setinfo()
        selectedButton = m.buttonGrp.getChild(m.top.selectedButtonIndex)
        selectedButton.focus = true
        m.buttonGrp.setFocus(true)
        m.buttonGrp.visible = true
    end if
end sub
