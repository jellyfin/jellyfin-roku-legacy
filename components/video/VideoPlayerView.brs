import "pkg:/source/utils/misc.brs"
import "pkg:/source/utils/config.brs"

sub init()
    ' Hide the overhang on init to prevent showing 2 clocks
    m.top.getScene().findNode("overhang").visible = false

    m.currentItem = m.global.queueManager.callFunc("getCurrentItem")

    m.top.id = m.currentItem.id

    ' Load meta data
    m.LoadMetaDataTask = CreateObject("roSGNode", "LoadVideoContentTask")
    m.LoadMetaDataTask.itemId = m.currentItem.id
    m.LoadMetaDataTask.itemType = m.currentItem.type
    m.LoadMetaDataTask.selectedAudioStreamIndex = m.currentItem.selectedAudioStreamIndex
    m.LoadMetaDataTask.observeField("content", "onVideoContentLoaded")
    m.LoadMetaDataTask.control = "RUN"

    m.playbackTimer = m.top.findNode("playbackTimer")
    m.bufferCheckTimer = m.top.findNode("bufferCheckTimer")
    m.top.observeField("state", "onState")
    m.top.observeField("content", "onContentChange")
    m.top.observeField("selectedSubtitle", "onSubtitleChange")

    m.playbackTimer.observeField("fire", "ReportPlayback")
    m.bufferPercentage = 0 ' Track whether content is being loaded
    m.playReported = false
    m.top.transcodeReasons = []
    m.bufferCheckTimer.duration = 30

    if m.global.session.user.settings["ui.design.hideclock"] = true
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

    m.buttonGrp = m.top.findNode("buttons")
    m.buttonGrp.observeField("escape", "onButtonGroupEscaped")
    m.buttonGrp.visible = false

    m.checkedForNextEpisode = false
    m.movieInfo = false
    m.guideLoaded = false
    m.suppressKey = false

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

sub onSubtitleChange()
    ' Save the current video position
    m.global.queueManager.callFunc("setTopStartingPoint", int(m.top.position) * 10000000&)

    m.top.control = "stop"

    m.LoadMetaDataTask.selectedSubtitleIndex = m.top.SelectedSubtitle
    m.LoadMetaDataTask.itemId = m.currentItem.id
    m.LoadMetaDataTask.observeField("content", "onVideoContentLoaded")
    m.LoadMetaDataTask.control = "RUN"
end sub

sub onPlaybackErrorDialogClosed(msg)
    sourceNode = msg.getRoSGNode()
    sourceNode.unobserveField("buttonSelected")
    sourceNode.unobserveField("wasClosed")

    m.global.sceneManager.callFunc("popScene")
end sub

sub onPlaybackErrorButtonSelected(msg)
    sourceNode = msg.getRoSGNode()
    sourceNode.close = true
end sub

sub showPlaybackErrorDialog(errorMessage as string)
    dialog = createObject("roSGNode", "Dialog")
    dialog.title = tr("Error During Playback")
    dialog.buttons = [tr("OK")]
    dialog.message = errorMessage
    dialog.observeField("buttonSelected", "onPlaybackErrorButtonSelected")
    dialog.observeField("wasClosed", "onPlaybackErrorDialogClosed")
    m.top.getScene().dialog = dialog
end sub

sub onVideoContentLoaded()
    m.LoadMetaDataTask.unobserveField("content")
    m.LoadMetaDataTask.control = "STOP"

    videoContent = m.LoadMetaDataTask.content
    m.LoadMetaDataTask.content = []

    ' If we have nothing to play, return to previous screen
    if not isValid(videoContent)
        showPlaybackErrorDialog(tr("There was an error retrieving the data for this item from the server."))
        return
    end if

    if not isValid(videoContent[0])
        showPlaybackErrorDialog(tr("There was an error retrieving the data for this item from the server."))
        return
    end if

    m.top.content = videoContent[0].content
    m.top.PlaySessionId = videoContent[0].PlaySessionId
    m.top.videoId = videoContent[0].id
    m.top.container = videoContent[0].container
    m.top.mediaSourceId = videoContent[0].mediaSourceId
    m.top.fullSubtitleData = videoContent[0].fullSubtitleData
    m.top.audioIndex = videoContent[0].audioIndex
    m.top.transcodeParams = videoContent[0].transcodeparams

    if m.LoadMetaDataTask.isIntro
        m.top.enableTrickPlay = false
    end if

    if isValid(m.top.audioIndex)
        m.top.audioTrack = (m.top.audioIndex + 1).toStr()
    else
        m.top.audioTrack = "2"
    end if

    m.top.setFocus(true)
    m.top.control = "play"
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
    if m.global.session.user.configuration.EnableNextEpisodeAutoPlay and not m.nextEpisodeButton.visible
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
        if isValid(m.top.id)
            if m.top.id <> "" and not m.checkedForNextEpisode and m.top.content.contenttype = 4
                m.getNextEpisodeTask.showID = m.currentItem.json.SeriesId
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
            m.top.callFunc("refresh")
        else
            ' If buffering has stopped Display dialog
            showPlaybackErrorDialog(tr("There was an error retrieving the data for this item from the server."))

            ' Stop playback and exit player
            m.top.control = "stop"
            m.top.backPressed = true
        end if
    end if

end sub

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

sub onButtonGroupEscaped()
    key = m.buttonGrp.escape
    if key = "up"
        m.buttonGrp.setFocus(false)
        m.buttonGrp.visible = false
    end if
    m.top.setFocus(true)
end sub

sub setinfo()
    'episode info
    if not m.getNextEpisodeTask.nextEpisodeData = invalid
        m.info = m.getNextEpisodeTask.nextEpisodeData.Items[0].Overview
        m.content = m.getNextEpisodeTask.nextEpisodeData.Items[0]
    else if not m.getItemQueryTask.getItemQueryData = invalid and not m.top.content.live = true 'movie info
        m.info = m.getItemQueryTask.getItemQueryData.Items.[0].Overview
        m.content = m.getItemQueryTask.getItemQueryData.Items.[0]
        print "Content = " m.content
    else if not m.getItemQueryTask.getItemQueryData = invalid and m.getItemQueryTask.getItemQueryData.Items.Count() > 0 'Live TV Content
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
                    m.top.selectPlaybackInfoPressed = true
                    m.top.control = "pause"
                    m.buttonGrp.visible = false
                    m.top.setFocus(true)
                end if
                if selectedButton.id = "info"
                    info()
                    m.top.control = "pause"
                    'return true
                end if
                if selectedButton.id = "cast"
                    print " Selected Item= "m.top.selectedItem
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
