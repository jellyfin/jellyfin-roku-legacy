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

    mediaSourceId = m.global.queueManager.callFunc("getCurrentItem").mediaSourceId

    if not isValid(mediaSourceId) or mediaSourceId = ""
        mediaSourceId = m.global.queueManager.callFunc("getCurrentItem").id
    end if

    m.getPlaybackInfoTask = createObject("roSGNode", "GetPlaybackInfoTask")
    m.getPlaybackInfoTask.videoID = mediaSourceId
    m.getPlaybackInfoTask.observeField("data", "onPlaybackInfoLoaded")

    m.global.sceneManager.callFunc("pushScene", m.view)
end sub

' -----------------
' Event Handlers
' -----------------

' User requested subtitle selection popup
sub onSelectSubtitlePressed()
    ' None is always first in the subtitle list
    subtitleData = {
        data: [{
            "Index": -1,
            "IsExternal": false,
            "Track": {
                "description": "None"
            },
            "Type": "subtitleselection"
        }]
    }

    for each item in m.view.fullSubtitleData
        item.type = "subtitleselection"

        if m.view.selectedSubtitle <> -1
            ' Subtitle is a track within the file
            if item.index = m.view.selectedSubtitle
                item.selected = true
            end if
        else
            ' Subtitle is from an external source
            availableSubtitleTrackIndex = availSubtitleTrackIdx(item.track.TrackName)
            if availableSubtitleTrackIndex <> -1

                ' Convert Jellyfin subtitle track name to Roku track name
                subtitleFullTrackName = m.view.availableSubtitleTracks[availableSubtitleTrackIndex].TrackName

                if subtitleFullTrackName = m.view.subtitleTrack
                    item.selected = true
                end if

            end if
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

    ' The selected encoded subtitle did not change.
    if m.view.selectedSubtitle <> -1 or m.selectedSubtitle.index <> -1
        if m.view.selectedSubtitle = m.selectedSubtitle.index then return
    end if

    ' The playbackData is now outdated and must be refreshed
    m.playbackData = invalid

    if LCase(m.selectedSubtitle.track.description) = "none"
        m.view.globalCaptionMode = "Off"
        m.view.subtitleTrack = ""

        if m.view.selectedSubtitle <> -1
            m.view.selectedSubtitle = -1
        end if

        return
    end if

    if m.selectedSubtitle.IsEncoded
        m.view.globalCaptionMode = "Off"
    else
        m.view.globalCaptionMode = "On"
    end if

    if m.selectedSubtitle.IsExternal
        availableSubtitleTrackIndex = availSubtitleTrackIdx(m.selectedSubtitle.Track.TrackName)
        if availableSubtitleTrackIndex = -1 then return

        m.view.subtitleTrack = m.view.availableSubtitleTracks[availableSubtitleTrackIndex].TrackName
    else
        m.view.selectedSubtitle = m.selectedSubtitle.Index
    end if
end sub

' User requested playback info
sub onSelectPlaybackInfoPressed()
    ' Check if we already have playback info and show it in a popup
    if isValid(m.playbackData) and isValid(m.playbackData.playbackinfo)
        m.global.sceneManager.callFunc("standardDialog", tr("Playback Info"), m.playbackData.playbackinfo)
        return
    end if

    m.getPlaybackInfoTask.control = "RUN"
end sub

' The playback info task has returned data
sub onPlaybackInfoLoaded()
    m.playbackData = m.getPlaybackInfoTask.data

    ' Check if we have playback info and show it in a popup
    if isValid(m.playbackData) and isValid(m.playbackData.playbackinfo)
        m.global.sceneManager.callFunc("standardDialog", tr("Playback Info"), m.playbackData.playbackinfo)
    end if
end sub

' Playback state change event handlers
sub onStateChange()
    if LCase(m.view.state) = "finished"
        ' Close any open dialogs
        if m.global.sceneManager.callFunc("isDialogOpen")
            m.global.sceneManager.callFunc("dismissDialog")
        end if

        ' If there is something next in the queue, play it
        if m.global.queueManager.callFunc("getPosition") < m.global.queueManager.callFunc("getCount") - 1
            m.global.sceneManager.callFunc("clearPreviousScene")
            m.global.queueManager.callFunc("moveForward")
            m.global.queueManager.callFunc("playQueue")
            return
        end if

        ' Playback completed, return user to previous screen
        m.global.sceneManager.callFunc("popScene")
        m.global.audioPlayer.loopMode = ""
    end if
end sub

' Roku translates the info provided in subtitleTracks into availableSubtitleTracks
' Including ignoring tracks, if they are not understood, thus making indexing unpredictable.
' This function translates between our internel selected subtitle index
' and the corresponding index in availableSubtitleTracks.
function availSubtitleTrackIdx(tracknameToFind as string) as integer
    idx = 0
    for each availTrack in m.view.availableSubtitleTracks
        ' The TrackName must contain the URL we supplied originally, though
        ' Roku mangles the name a bit, so we check if the URL is a substring, rather
        ' than strict equality
        if Instr(1, availTrack.TrackName, tracknameToFind)
            return idx
        end if
        idx = idx + 1
    end for
    return -1
end function
