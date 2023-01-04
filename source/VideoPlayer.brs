function VideoPlayer(id, mediaSourceId = invalid, audio_stream_idx = 1, subtitle_idx = -1, forceTranscoding = false, showIntro = true, allowResumeDialog = true)
    ' Get video controls and UI
    video = CreateObject("roSGNode", "JFVideo")
    video.id = id
    AddVideoContent(video, mediaSourceId, audio_stream_idx, subtitle_idx, -1, forceTranscoding, showIntro, allowResumeDialog)

    if video.errorMsg = "introaborted"
        return video
    end if

    if video.content = invalid
        return invalid
    end if
    jellyfin_blue = "#00a4dcFF"

    video.retrievingBar.filledBarBlendColor = jellyfin_blue
    video.bufferingBar.filledBarBlendColor = jellyfin_blue
    video.trickPlayBar.filledBarBlendColor = jellyfin_blue
    return video
end function

sub AddVideoContent(video, mediaSourceId, audio_stream_idx = 1, subtitle_idx = -1, playbackPosition = -1, forceTranscoding = false, showIntro = true, allowResumeDialog = true)
    video.content = createObject("RoSGNode", "ContentNode")
    meta = ItemMetaData(video.id)
    if meta = invalid
        video.content = invalid
        return
    end if
    m.videotype = meta.type

    ' Special handling for "Programs" or "Vidoes" launched from "On Now" or elsewhere on the home screen...
    ' basically anything that is a Live Channel.
    if meta.json.ChannelId <> invalid
        if meta.json.EpisodeTitle <> invalid
            meta.title = meta.json.EpisodeTitle
        else if meta.json.Name <> invalid
            meta.title = meta.json.Name
        end if
        meta.showID = meta.json.id
        meta.live = true
        if meta.json.type = "Program"
            video.id = meta.json.ChannelId
        else
            video.id = meta.json.id
        end if
    end if

    if m.videotype = "Episode" or m.videotype = "Series"
        video.runTime = (meta.json.RunTimeTicks / 10000000.0)
        video.content.contenttype = "episode"
    end if

    video.content.title = meta.title
    video.showID = meta.showID

    if playbackPosition = -1
        playbackPosition = meta.json.UserData.PlaybackPositionTicks
        if allowResumeDialog
            if playbackPosition > 0
                dialogResult = startPlayBackOver(playbackPosition)
                'Dialog returns -1 when back pressed, 0 for resume, and 1 for start over
                if dialogResult = -1
                    'User pressed back, return invalid and don't load video
                    video.content = invalid
                    return
                else if dialogResult = 1
                    'Start Over selected, change position to 0
                    playbackPosition = 0
                else if dialogResult = 2
                    'Mark this item as watched, refresh the page, and return invalid so we don't load the video
                    MarkItemWatched(video.id)
                    video.content.watched = not video.content.watched
                    group = m.scene.focusedChild
                    group.timeLastRefresh = CreateObject("roDateTime").AsSeconds()
                    group.callFunc("refresh")
                    video.content = invalid
                    return
                else if dialogResult = 3
                    'get series ID based off episiode ID
                    params = {
                        ids: video.Id
                    }
                    url = Substitute("Users/{0}/Items/", get_setting("active_user"))
                    resp = APIRequest(url, params)
                    data = getJson(resp)
                    for each item in data.Items
                        m.series_id = item.SeriesId
                    end for
                    'Get series json data
                    params = {
                        ids: m.series_id
                    }
                    url = Substitute("Users/{0}/Items/", get_setting("active_user"))
                    resp = APIRequest(url, params)
                    data = getJson(resp)
                    for each item in data.Items
                        m.tmp = item
                    end for
                    'Create Series Scene
                    CreateSeriesDetailsGroup(m.tmp)
                    video.content = invalid
                    return

                else if dialogResult = 4
                    'get Season/Series ID based off episiode ID
                    params = {
                        ids: video.Id
                    }
                    url = Substitute("Users/{0}/Items/", get_setting("active_user"))
                    resp = APIRequest(url, params)
                    data = getJson(resp)
                    for each item in data.Items
                        m.season_id = item.SeasonId
                        m.series_id = item.SeriesId
                    end for
                    'Get Series json data
                    params = {
                        ids: m.season_id
                    }
                    url = Substitute("Users/{0}/Items/", get_setting("active_user"))
                    resp = APIRequest(url, params)
                    data = getJson(resp)
                    for each item in data.Items
                        m.Season_tmp = item
                    end for
                    'Get Season json data
                    params = {
                        ids: m.series_id
                    }
                    url = Substitute("Users/{0}/Items/", get_setting("active_user"))
                    resp = APIRequest(url, params)
                    data = getJson(resp)
                    for each item in data.Items
                        m.Series_tmp = item
                    end for
                    'Create Season Scene
                    CreateSeasonDetailsGroup(m.Series_tmp, m.Season_tmp)
                    video.content = invalid
                    return

                else if dialogResult = 5
                    'get  episiode ID
                    params = {
                        ids: video.Id
                    }
                    url = Substitute("Users/{0}/Items/", get_setting("active_user"))
                    resp = APIRequest(url, params)
                    data = getJson(resp)
                    for each item in data.Items
                        m.episode_id = item
                    end for
                    'Create Episode Scene
                    CreateMovieDetailsGroup(m.episode_id)
                    video.content = invalid
                    return
                end if
            end if
        end if
    end if

    ' Don't attempt to play an intro for an intro video
    if showIntro
        ' Do not play intros when resuming playback
        if playbackPosition = 0
            if not PlayIntroVideo(video.id, audio_stream_idx)
                video.errorMsg = "introaborted"
                return
            end if
        end if
    end if

    video.content.PlayStart = int(playbackPosition / 10000000)

    ' Call PlayInfo from server
    if mediaSourceId = invalid
        mediaSourceId = video.id
    end if
    if meta.live then mediaSourceId = "" ' Don't send mediaSourceId for Live media

    m.playbackInfo = ItemPostPlaybackInfo(video.id, mediaSourceId, audio_stream_idx, subtitle_idx, playbackPosition)
    video.videoId = video.id
    video.mediaSourceId = mediaSourceId
    video.audioIndex = audio_stream_idx

    if m.playbackInfo = invalid
        video.content = invalid
        return
    end if

    params = {}
    video.PlaySessionId = m.playbackInfo.PlaySessionId

    if meta.live
        video.content.live = true
        video.content.StreamFormat = "hls"
    end if

    video.container = getContainerType(meta)

    if m.playbackInfo.MediaSources[0] = invalid
        m.playbackInfo = meta.json
    end if

    subtitles = sortSubtitles(meta.id, m.playbackInfo.MediaSources[0].MediaStreams)
    if get_user_setting("playback.subs.onlytext") = "true"
        safesubs = []
        for each subtitle in subtitles["all"]
            if subtitle["IsTextSubtitleStream"]
                safesubs.push(subtitle)
            end if
        end for
        video.Subtitles = safesubs
    else
        video.Subtitles = subtitles["all"]
    end if

    if meta.live
        video.transcodeParams = {
            "MediaSourceId": m.playbackInfo.MediaSources[0].Id,
            "LiveStreamId": m.playbackInfo.MediaSources[0].LiveStreamId,
            "PlaySessionId": video.PlaySessionId
        }
    end if

    video.content.SubtitleTracks = subtitles["text"]

    ' 'TODO: allow user selection of subtitle track before playback initiated, for now set to no subtitles

    video.directPlaySupported = m.playbackInfo.MediaSources[0].SupportsDirectPlay
    fully_external = false


    ' For h264/hevc video, Roku spec states that it supports specfic encoding levels
    ' The device can decode content with a Higher Encoding level but may play it back with certain
    ' artifacts. If the user preference is set, and the only reason the server says we need to
    ' transcode is that the Encoding Level is not supported, then try to direct play but silently
    ' fall back to the transcode if that fails.
    if m.playbackInfo.MediaSources[0].MediaStreams.Count() > 0 and meta.live = false
        tryDirectPlay = get_user_setting("playback.tryDirect.h264ProfileLevel") = "true" and m.playbackInfo.MediaSources[0].MediaStreams[0].codec = "h264"
        tryDirectPlay = tryDirectPlay or (get_user_setting("playback.tryDirect.hevcProfileLevel") = "true" and m.playbackInfo.MediaSources[0].MediaStreams[0].codec = "hevc")
        if tryDirectPlay and m.playbackInfo.MediaSources[0].TranscodingUrl <> invalid and forceTranscoding = false
            transcodingReasons = getTranscodeReasons(m.playbackInfo.MediaSources[0].TranscodingUrl)
            if transcodingReasons.Count() = 1 and transcodingReasons[0] = "VideoLevelNotSupported"
                video.directPlaySupported = true
                video.transcodeAvailable = true
            end if
        end if
    end if

    if video.directPlaySupported
        protocol = LCase(m.playbackInfo.MediaSources[0].Protocol)
        if protocol <> "file"
            uriRegex = CreateObject("roRegex", "^(.*:)//([A-Za-z0-9\-\.]+)(:[0-9]+)?(.*)$", "")
            uri = uriRegex.Match(m.playbackInfo.MediaSources[0].Path)
            ' proto $1, host $2, port $3, the-rest $4
            localhost = CreateObject("roRegex", "^localhost$|^127(?:\.[0-9]+){0,2}\.[0-9]+$|^(?:0*\:)*?:?0*1$", "i")
            ' https://stackoverflow.com/questions/8426171/what-regex-will-match-all-loopback-addresses
            if localhost.isMatch(uri[2])
                ' if the domain of the URI is local to the server,
                ' create a new URI by appending the received path to the server URL
                ' later we will substitute the users provided URL for this case
                video.content.url = buildURL(uri[4])
            else
                fully_external = true
                video.content.url = m.playbackInfo.MediaSources[0].Path
            end if
        else:
            params.append({
                "Static": "true",
                "Container": video.container,
                "PlaySessionId": video.PlaySessionId,
                "AudioStreamIndex": audio_stream_idx
            })
            if mediaSourceId <> ""
                params.MediaSourceId = mediaSourceId
            end if
            video.content.url = buildURL(Substitute("Videos/{0}/stream", video.id), params)

        end if
        video.isTranscoded = false
    else
        if m.playbackInfo.MediaSources[0].TranscodingUrl = invalid
            ' If server does not provide a transcode URL, display a message to the user
            m.global.sceneManager.callFunc("userMessage", tr("Error Getting Playback Information"), tr("An error was encountered while playing this item.  Server did not provide required transcoding data."))
            video.content = invalid
            return
        end if
        ' Get transcoding reason
        video.transcodeReasons = getTranscodeReasons(m.playbackInfo.MediaSources[0].TranscodingUrl)
        video.content.url = buildURL(m.playbackInfo.MediaSources[0].TranscodingUrl)
        video.isTranscoded = true
    end if

    video.content.setCertificatesFile("common:/certs/ca-bundle.crt")
    video.audioTrack = (audio_stream_idx + 1).ToStr() ' Roku's track indexes count from 1. Our index is zero based

    ' Perform relevant setup work for selected subtitle, and return the index of the subtitle
    ' is enabled/will be enabled, indexed on the provided list of subtitles
    video.SelectedSubtitle = setupSubtitle(video, video.Subtitles, subtitle_idx)

    if not fully_external
        video.content = authorize_request(video.content)
    end if

end sub

function PlayIntroVideo(video_id, audio_stream_idx) as boolean
    ' Intro videos only play if user has cinema mode setting enabled
    if get_user_setting("playback.cinemamode") = "true"

        ' Check if server has intro videos setup and available
        introVideos = GetIntroVideos(video_id)

        if introVideos = invalid then return true

        if introVideos.TotalRecordCount > 0
            ' Bypass joke pre-roll
            if lcase(introVideos.items[0].name) = "rick roll'd" then return true

            introVideo = VideoPlayer(introVideos.items[0].id, introVideos.items[0].id, audio_stream_idx, defaultSubtitleTrackFromVid(video_id), false, false)

            port = CreateObject("roMessagePort")
            introVideo.observeField("state", port)
            m.global.sceneManager.callFunc("pushScene", introVideo)
            introPlaying = true

            while introPlaying
                msg = wait(0, port)
                if type(msg) = "roSGNodeEvent"
                    if msg.GetData() = "finished"
                        m.global.sceneManager.callFunc("clearPreviousScene")
                        introPlaying = false
                    else if msg.GetData() = "stopped"
                        introPlaying = false
                        return false
                    end if
                end if
            end while
        end if
    end if
    return true
end function

'
' Extract array of Transcode Reasons from the content URL
' @returns Array of Strings
function getTranscodeReasons(url as string) as object

    regex = CreateObject("roRegex", "&TranscodeReasons=([^&]*)", "")
    match = regex.Match(url)

    if match.count() > 1
        return match[1].Split(",")
    end if

    return []
end function

'Opens dialog asking user if they want to resume video or start playback over only on the home screen
function startPlayBackOver(time as longinteger) as integer
    if m.scene.focusedChild.focusedChild.overhangTitle = tr("Home") and (m.videotype = "Episode" or m.videotype = "Series")
        return option_dialog([tr("Resume playing at ") + ticksToHuman(time) + ".", tr("Start over from the beginning."), tr("Watched"), tr("Go to series"), tr("Go to season"), tr("Go to episode")])
    else
        return option_dialog(["Resume playing at " + ticksToHuman(time) + ".", "Start over from the beginning."])
    end if
end function

function directPlaySupported(meta as object) as boolean
    devinfo = CreateObject("roDeviceInfo")
    if meta.json.MediaSources[0] <> invalid and meta.json.MediaSources[0].SupportsDirectPlay = false
        return false
    end if

    if meta.json.MediaStreams[0] = invalid
        return false
    end if

    streamInfo = { Codec: meta.json.MediaStreams[0].codec }
    if meta.json.MediaStreams[0].Profile <> invalid and meta.json.MediaStreams[0].Profile.len() > 0
        streamInfo.Profile = LCase(meta.json.MediaStreams[0].Profile)
    end if
    if meta.json.MediaSources[0].container <> invalid and meta.json.MediaSources[0].container.len() > 0
        'CanDecodeVideo() requires the .container to be format: “mp4”, “hls”, “mkv”, “ism”, “dash”, “ts” if its to direct stream
        if meta.json.MediaSources[0].container = "mov"
            streamInfo.Container = "mp4"
        else
            streamInfo.Container = meta.json.MediaSources[0].container
        end if
    end if

    decodeResult = devinfo.CanDecodeVideo(streamInfo)
    return decodeResult <> invalid and decodeResult.result

end function

function getContainerType(meta as object) as string
    ' Determine the file type of the video file source
    if meta.json.mediaSources = invalid then return ""

    container = meta.json.mediaSources[0].container
    if container = invalid
        container = ""
    else if container = "m4v" or container = "mov"
        container = "mp4"
    end if

    return container
end function

function getAudioFormat(meta as object) as string
    ' Determine the codec of the audio file source
    if meta.json.mediaSources = invalid then return ""

    audioInfo = getAudioInfo(meta)
    if audioInfo.count() = 0 or audioInfo[0].codec = invalid then return ""
    return audioInfo[0].codec
end function

function getAudioInfo(meta as object) as object
    ' Return audio metadata for a given stream
    results = []
    for each source in meta.json.mediaSources[0].mediaStreams
        if source["type"] = "Audio"
            results.push(source)
        end if
    end for
    return results
end function

sub autoPlayNextEpisode(videoID as string, showID as string)
    ' use web client setting
    if m.user.Configuration.EnableNextEpisodeAutoPlay
        ' query API for next episode ID
        url = Substitute("Shows/{0}/Episodes", showID)
        urlParams = { "UserId": get_setting("active_user") }
        urlParams.Append({ "StartItemId": videoID })
        urlParams.Append({ "Limit": 2 })
        resp = APIRequest(url, urlParams)
        data = getJson(resp)

        if data <> invalid and data.Items.Count() = 2
            ' setup new video node
            nextVideo = CreateVideoPlayerGroup(data.Items[1].Id, invalid, 1, false, false)
            ' remove last videoplayer scene
            m.global.sceneManager.callFunc("clearPreviousScene")
            if nextVideo <> invalid
                m.global.sceneManager.callFunc("pushScene", nextVideo)
            else
                m.global.sceneManager.callFunc("popScene")
            end if
        else
            ' can't play next episode
            m.global.sceneManager.callFunc("popScene")
        end if
    else
        m.global.sceneManager.callFunc("popScene")
    end if
end sub

' Returns an array of playback info to be displayed during playback.
' In the future, with a custom playback info view, we can return an associated array.
function GetPlaybackInfo()
    sessions = api_API().sessions.get()
    if sessions <> invalid and sessions.Count() > 0
        return GetTranscodingStats(sessions[0])
    end if

    errMsg = tr("Unable to get playback information")
    return [errMsg]
end function

function GetTranscodingStats(session)
    sessionStats = []

    if isValid(session.TranscodingInfo) and session.TranscodingInfo.Count() > 0
        transcodingReasons = session.TranscodingInfo.TranscodeReasons
        videoCodec = session.TranscodingInfo.VideoCodec
        audioCodec = session.TranscodingInfo.AudioCodec
        totalBitrate = session.TranscodingInfo.Bitrate
        audioChannels = session.TranscodingInfo.AudioChannels

        if isValid(transcodingReasons) and transcodingReasons.Count() > 0
            sessionStats.push("** " + tr("Transcoding Information") + " **")
            for each item in transcodingReasons
                sessionStats.push(tr("Reason") + ": " + item)
            end for
        end if

        if isValid(videoCodec)
            data = tr("Video Codec") + ": " + videoCodec
            if session.TranscodingInfo.IsVideoDirect
                data = data + " (" + tr("direct") + ")"
            end if
            sessionStats.push(data)
        end if

        if isValid(audioCodec)
            data = tr("Audio Codec") + ": " + audioCodec
            if session.TranscodingInfo.IsAudioDirect
                data = data + " (" + tr("direct") + ")"
            end if
            sessionStats.push(data)
        end if

        if isValid(totalBitrate)
            data = tr("Total Bitrate") + ": " + getDisplayBitrate(totalBitrate)
            sessionStats.push(data)
        end if

        if isValid(audioChannels)
            data = tr("Audio Channels") + ": " + Str(audioChannels)
            sessionStats.push(data)
        end if
    end if

    if havePlaybackInfo()
        stream = m.playbackInfo.mediaSources[0].MediaStreams[0]
        sessionStats.push("** " + tr("Stream Information") + " **")
        if isValid(stream.Container)
            data = tr("Container") + ": " + stream.Container
            sessionStats.push(data)
        end if
        if isValid(stream.Size)
            data = tr("Size") + ": " + stream.Size
            sessionStats.push(data)
        end if
        if isValid(stream.BitRate)
            data = tr("Bit Rate") + ": " + getDisplayBitrate(stream.BitRate)
            sessionStats.push(data)
        end if
        if isValid(stream.Codec)
            data = tr("Codec") + ": " + stream.Codec
            sessionStats.push(data)
        end if
        if isValid(stream.CodecTag)
            data = tr("Codec Tag") + ": " + stream.CodecTag
            sessionStats.push(data)
        end if
        if isValid(stream.VideoRangeType)
            data = tr("Video range type") + ": " + stream.VideoRangeType
            sessionStats.push(data)
        end if
        if isValid(stream.PixelFormat)
            data = tr("Pixel format") + ": " + stream.PixelFormat
            sessionStats.push(data)
        end if
        if isValid(stream.Width) and isValid(stream.Height)
            data = tr("WxH") + ": " + Str(stream.Width) + " x " + Str(stream.Height)
            sessionStats.push(data)
        end if
        if isValid(stream.Level)
            data = tr("Level") + ": " + Str(stream.Level)
            sessionStats.push(data)
        end if
    end if

    return sessionStats
end function

function havePlaybackInfo()
    if not isValid(m.playbackInfo)
        return false
    end if

    if not isValid(m.playbackInfo.mediaSources)
        return false
    end if

    if m.playbackInfo.mediaSources.Count() <= 0
        return false
    end if

    if not isValid(m.playbackInfo.mediaSources[0].MediaStreams)
        return false
    end if

    if m.playbackInfo.mediaSources[0].MediaStreams.Count() <= 0
        return false
    end if

    return true
end function

function getDisplayBitrate(bitrate)
    if bitrate > 1000000
        return Str(Fix(bitrate / 1000000)) + " Mbps"
    else
        return Str(Fix(bitrate / 1000)) + " Kbps"
    end if
end function
