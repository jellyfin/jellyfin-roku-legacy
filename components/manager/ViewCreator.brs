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
    m.getPlaybackInfoTask = createObject("roSGNode", "GetPlaybackInfoTask")
    m.getPlaybackInfoTask.videoID = m.global.queueManager.callFunc("getCurrentItem").id
    m.getPlaybackInfoTask.observeField("data", "onPlaybackInfoLoaded")

    m.view = CreateObject("roSGNode", "VideoPlayerView")
    m.view.observeField("state", "onStateChange")
    m.view.observeField("selectPlaybackInfoPressed", "onSelectPlaybackInfoPressed")
    m.view.observeField("selectSubtitlePressed", "onSelectSubtitlePressed")
    m.global.sceneManager.callFunc("pushScene", m.view)
end sub


'
' Event Handlers
' -----------------

' User requested subtitle selection popup
sub onSelectSubtitlePressed()
    subtitleData = {
        data: [
            { id: "none", text: "None" },
            { id: "abc123", text: "Option 2" }
        ]
    }

    for each item in subtitleData.data
        if item.id = m.selectedSubtitle.id
            item.selected = true
        end if
    end for

    m.global.sceneManager.callFunc("radioDialog", tr("Select Subtitles"), subtitleData)
    m.global.sceneManager.observeField("returnData", "onSelectionMade")
end sub

sub onSelectionMade()
    m.global.sceneManager.unobserveField("returnData")
    m.selectedSubtitle = m.global.sceneManager.returnData
end sub

' User requested playback info
sub onSelectPlaybackInfoPressed()
    if isValid(m.playbackData?.playbackinfo)
        m.global.sceneManager.callFunc("standardDialog", tr("Playback Info"), m.playbackData.playbackinfo)
        return
    end if

    m.getPlaybackInfoTask.control = "RUN"
end sub

' Playback info task has returned data
sub onPlaybackInfoLoaded()
    m.playbackData = m.getPlaybackInfoTask.data
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
        else
            ' Playback completed, return user to previous screen
            m.global.sceneManager.callFunc("popScene")
        end if
    end if
end sub
