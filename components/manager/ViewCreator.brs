'
' View Creators
' ----------------

' Play Audio
sub CreateAudioPlayerView()
    m.view = CreateObject("roSGNode", "AudioPlayerView")
    m.view.observeField("state", "onStateChange")
    m.global.sceneManager.callFunc("pushScene", m.view)
end sub

' Play Video
sub CreateVideoPlayerView()
    m.playbackData = {}
    m.selectedSubtitle = {}

    m.view = CreateObject("roSGNode", "VideoPlayerView")
    m.view.observeField("state", "onStateChange")
    m.view.observeField("selectPlaybackInfoPressed", "onSelectPlaybackInfoPressed")
    m.view.observeField("selectSubtitlePressed", "onSelectSubtitlePressed")

    m.getPlaybackInfoTask = createObject("roSGNode", "GetPlaybackInfoTask")
    m.getPlaybackInfoTask.videoID = m.global.queueManager.callFunc("getCurrentItem").id
    m.getPlaybackInfoTask.observeField("data", "onPlaybackInfoLoaded")

    m.global.sceneManager.callFunc("pushScene", m.view)
end sub


'
' Event Handlers
' -----------------

' User requested subtitle selection popup
sub onSelectSubtitlePressed()

    ' None is always first in the subtitle list
    subtitleData = {
        data: [{ "description": "None", "type": "subtitleselection" }]
    }

    for each item in m.view.content.subtitletracks
        item.type = "subtitleselection"

        if item.description = m.selectedSubtitle.description
            item.selected = true
        end if

        subtitleData.data.push(item)
    end for

    m.global.sceneManager.callFunc("radioDialog", tr("Select Subtitles"), subtitleData)
    m.global.sceneManager.observeField("returnData", "onSelectionMade")
end sub

' User has selected something from the radioDialog popup
sub onSelectionMade()
    m.global.sceneManager.unobserveField("returnData")

    if not isValid(m.global.sceneManager.returnData) then return
    if not isValid(m.global.sceneManager.returnData.type) then return

    if LCase(m.global.sceneManager.returnData.type) = "subtitleselection"
        processSubtitleSelection()
    end if
end sub

sub processSubtitleSelection()
    m.selectedSubtitle = m.global.sceneManager.returnData

    if LCase(m.selectedSubtitle.description) = "none"
        m.view.globalCaptionMode = "Off"
        m.view.subtitleTrack = ""
        return
    end if

    m.view.globalCaptionMode = "On"
    m.view.subtitleTrack = m.selectedSubtitle.TrackName
end sub

' User requested playback info
sub onSelectPlaybackInfoPressed()

    ' Check if we already have playback info and show it in a popup
    if isValid(m.playbackData?.playbackinfo)
        m.global.sceneManager.callFunc("standardDialog", tr("Playback Info"), m.playbackData.playbackinfo)
        return
    end if

    m.getPlaybackInfoTask.control = "RUN"
end sub

' The playback info task has returned data
sub onPlaybackInfoLoaded()
    m.playbackData = m.getPlaybackInfoTask.data

    ' Check if we have playback info and show it in a popup
    if isValid(m.playbackData?.playbackinfo)
        m.global.sceneManager.callFunc("standardDialog", tr("Playback Info"), m.playbackData.playbackinfo)
    end if
end sub


' Playback state change event handlers
sub onStateChange()
    if LCase(m.view.state) = "finished"
        ' If there is something next in the queue, play it
        if m.global.queueManager.callFunc("getPosition") < m.global.queueManager.callFunc("getCount") - 1
            m.global.sceneManager.callFunc("clearPreviousScene")
            m.global.queueManager.callFunc("moveForward")
            m.global.queueManager.callFunc("playQueue")
            return
        end if

        ' Playback completed, return user to previous screen
        m.global.sceneManager.callFunc("popScene")
    end if
end sub
