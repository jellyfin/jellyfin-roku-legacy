sub init()
    m.top.functionName = "loadItems"

    m.top.limit = 60
    usersettingLimit = get_user_setting("itemgrid.Limit")

    if usersettingLimit <> invalid
        m.top.limit = usersettingLimit
    end if
end sub

sub loadItems()
    m.top.content = [LoadItems_VideoPlayer(m.top.itemId)]
end sub

function LoadItems_VideoPlayer(id, mediaSourceId = invalid, audio_stream_idx = 1, subtitle_idx = -1, forceTranscoding = false, showIntro = true, allowResumeDialog = true)

    video = {}
    video.id = id
    video.content = createObject("RoSGNode", "ContentNode")

    LoadItems_AddVideoContent(video, mediaSourceId, audio_stream_idx, subtitle_idx, -1, forceTranscoding, showIntro, allowResumeDialog)

    if video.errorMsg = "introaborted"
        return video
    end if

    if video.content = invalid
        return invalid
    end if

    return video
end function

sub LoadItems_AddVideoContent(video, mediaSourceId, audio_stream_idx = 1, subtitle_idx = -1, playbackPosition = -1, forceTranscoding = false, showIntro = true, allowResumeDialog = true)

    meta = ItemMetaData(video.id)

    if not isValid(meta)
        video.content = invalid
        return
    end if

    videotype = LCase(meta.type)

    if videotype = "episode" or videotype = "series"
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
                if dialogResult.indexselected = -1
                    'User pressed back, return invalid and don't load video
                    video.content = invalid
                    return
                else if dialogResult.indexselected = 1
                    'Start Over selected, change position to 0
                    playbackPosition = 0
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


    if not isValid(mediaSourceId) then mediaSourceId = video.id
    if meta.live then mediaSourceId = ""

    m.playbackInfo = ItemPostPlaybackInfo(video.id, mediaSourceId, audio_stream_idx, subtitle_idx, playbackPosition)
    video.videoId = video.id
    video.mediaSourceId = mediaSourceId
    video.audioIndex = audio_stream_idx

    if not isValid(m.playbackInfo)
        video.content = invalid
        return
    end if

    video.PlaySessionId = m.playbackInfo.PlaySessionId

    if meta.live
        video.content.live = true
        video.content.StreamFormat = "hls"
    end if

    video.container = getContainerType(meta)

    if not isValid(m.playbackInfo.MediaSources[0])
        m.playbackInfo = meta.json
    end if

    addSubtitlesToVideo(video, meta)

    if meta.live
        video.transcodeParams = {
            "MediaSourceId": m.playbackInfo.MediaSources[0].Id,
            "LiveStreamId": m.playbackInfo.MediaSources[0].LiveStreamId,
            "PlaySessionId": video.PlaySessionId
        }
    end if


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
        addVideoContentURL(video, mediaSourceId, audio_stream_idx, fully_external)
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

sub addVideoContentURL(video, mediaSourceId, audio_stream_idx, fully_external)
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
        params = {}

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
end sub

sub addSubtitlesToVideo(video, meta)
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
    video.content.SubtitleTracks = subtitles["text"]
end sub


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
function startPlayBackOver(time as longinteger)

    ' If we're inside a play queue, start the episode from the beginning
    if m.global.queueManager.callFunc("getCount") > 1 then return { indexselected: 1 }

    resumeData = [
        "Resume playing at " + ticksToHuman(time) + ".",
        "Start over from the beginning."
    ]

    m.global.sceneManager.callFunc("optionDialog", tr("Playback Options"), ["Choose an option"], resumeData)

    while not isValid(m.global.sceneManager.returnData)

    end while

    return m.global.sceneManager.returnData
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
            nextVideo = invalid
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

' Roku translates the info provided in subtitleTracks into availableSubtitleTracks
' Including ignoring tracks, if they are not understood, thus making indexing unpredictable.
' This function translates between our internel selected subtitle index
' and the corresponding index in availableSubtitleTracks.
function availSubtitleTrackIdx(video, sub_idx) as integer
    url = video.Subtitles[sub_idx].Track.TrackName
    idx = 0
    for each availTrack in video.availableSubtitleTracks
        ' The TrackName must contain the URL we supplied originally, though
        ' Roku mangles the name a bit, so we check if the URL is a substring, rather
        ' than strict equality
        if Instr(1, availTrack.TrackName, url)
            return idx
        end if
        idx = idx + 1
    end for
    return -1
end function

' Identify the default subtitle track for a given video id
' returns the server-side track index for the appriate subtitle
function defaultSubtitleTrackFromVid(video_id) as integer
    meta = ItemMetaData(video_id)
    if meta?.json?.mediaSources <> invalid
        subtitles = sortSubtitles(meta.id, meta.json.MediaSources[0].MediaStreams)
        default_text_subs = defaultSubtitleTrack(subtitles["all"], true) ' Find correct subtitle track (forced text)
        if default_text_subs <> -1
            return default_text_subs
        else
            if get_user_setting("playback.subs.onlytext") = "false"
                return defaultSubtitleTrack(subtitles["all"]) ' if no appropriate text subs exist, allow non-text
            else
                return -1
            end if
        end if
    end if
    ' No valid mediaSources (i.e. LiveTV)
    return -1
end function


' Identify the default subtitle track
' if "requires_text" is true, only return a track if it is textual
'     This allows forcing text subs, since roku requires transcoding of non-text subs
' returns the server-side track index for the appriate subtitle
function defaultSubtitleTrack(sorted_subtitles, require_text = false) as integer
    if m.user.Configuration.SubtitleMode = "None"
        return -1 ' No subtitles desired: select none
    end if

    for each item in sorted_subtitles
        ' Only auto-select subtitle if language matches preference
        languageMatch = (m.user.Configuration.SubtitleLanguagePreference = item.Track.Language)
        ' Ensure textuality of subtitle matches preferenced passed as arg
        matchTextReq = ((require_text and item.IsTextSubtitleStream) or not require_text)
        if languageMatch and matchTextReq
            if m.user.Configuration.SubtitleMode = "Default" and (item.isForced or item.IsDefault or item.IsExternal)
                return item.Index ' Finds first forced, or default, or external subs in sorted list
            else if m.user.Configuration.SubtitleMode = "Always" and not item.IsForced
                return item.Index ' Select the first non-forced subtitle option in the sorted list
            else if m.user.Configuration.SubtitleMode = "OnlyForced" and item.IsForced
                return item.Index ' Select the first forced subtitle option in the sorted list
            else if m.user.Configuration.SubtitlePlaybackMode = "Smart" and (item.isForced or item.IsDefault or item.IsExternal)
                ' Simplified "Smart" logic here mimics Default (as that is fallback behavior normally)
                ' Avoids detecting preferred audio language (as is utilized in main client)
                return item.Index
            end if
        end if
    end for
    return -1 ' Keep current default behavior of "None", if no correct subtitle is identified
end function

' Given a set of subtitles, and a subtitle index (the index on the server, not in the list provided)
' this will set all relevant settings for roku (mainly closed captions) and return the index of the
' subtitle track specified, but indexed based on the provided list of subtitles
function setupSubtitle(video, subtitles, subtitle_idx = -1) as integer
    if subtitle_idx = -1
        ' If we are not using text-based subtitles, turn them off
        video.globalCaptionMode = "Off"
        return -1
    end if

    ' Translate the raw index to one relative to the provided list
    subtitleSelIdx = getSubtitleSelIdxFromSubIdx(subtitles, subtitle_idx)

    selectedSubtitle = subtitles[subtitleSelIdx]

    if selectedSubtitle.IsEncoded
        ' With encoded subtitles, turn off captions
        video.globalCaptionMode = "Off"
    else
        ' If this is a text-based subtitle, set relevant settings for roku captions
        video.globalCaptionMode = "On"
        video.subtitleTrack = video.availableSubtitleTracks[availSubtitleTrackIdx(video, subtitleSelIdx)].TrackName
    end if

    return subtitleSelIdx

end function

' The subtitle index on the server differs from the index we track locally
' This function converts the former into the latter
function getSubtitleSelIdxFromSubIdx(subtitles, sub_idx) as integer
    selIdx = 0
    if sub_idx = -1 then return -1
    for each item in subtitles
        if item.Index = sub_idx
            return selIdx
        end if
        selIdx = selIdx + 1
    end for
    return -1
end function

'Checks available subtitle tracks and puts subtitles in forced, default, and non-default/forced but preferred language at the top
function sortSubtitles(id as string, MediaStreams)
    m.user = AboutMe()
    tracks = { "forced": [], "default": [], "normal": [] }
    'Too many args for using substitute
    prefered_lang = m.user.Configuration.SubtitleLanguagePreference
    for each stream in MediaStreams
        if stream.type = "Subtitle"

            url = ""
            if stream.DeliveryUrl <> invalid
                url = buildURL(stream.DeliveryUrl)
            end if

            stream = {
                "Track": { "Language": stream.language, "Description": stream.displaytitle, "TrackName": url },
                "IsTextSubtitleStream": stream.IsTextSubtitleStream,
                "Index": stream.index,
                "IsDefault": stream.IsDefault,
                "IsForced": stream.IsForced,
                "IsExternal": stream.IsExternal,
                "IsEncoded": stream.DeliveryMethod = "Encode"
            }
            if stream.isForced
                trackType = "forced"
            else if stream.IsDefault
                trackType = "default"
            else
                trackType = "normal"
            end if
            if prefered_lang <> "" and prefered_lang = stream.Track.Language
                tracks[trackType].unshift(stream)
            else
                tracks[trackType].push(stream)
            end if
        end if
    end for

    tracks["default"].append(tracks["normal"])
    tracks["forced"].append(tracks["default"])

    textTracks = []
    for i = 0 to tracks["forced"].count() - 1
        if tracks["forced"][i].IsTextSubtitleStream
            textTracks.push(tracks["forced"][i].Track)
        end if
    end for
    return { "all": tracks["forced"], "text": textTracks }
end function

function getSubtitleLanguages()
    return {
        "aar": "Afar",
        "abk": "Abkhazian",
        "ace": "Achinese",
        "ach": "Acoli",
        "ada": "Adangme",
        "ady": "Adyghe; Adygei",
        "afa": "Afro-Asiatic languages",
        "afh": "Afrihili",
        "afr": "Afrikaans",
        "ain": "Ainu",
        "aka": "Akan",
        "akk": "Akkadian",
        "alb": "Albanian",
        "ale": "Aleut",
        "alg": "Algonquian languages",
        "alt": "Southern Altai",
        "amh": "Amharic",
        "ang": "English, Old (ca.450-1100)",
        "anp": "Angika",
        "apa": "Apache languages",
        "ara": "Arabic",
        "arc": "Official Aramaic (700-300 BCE); Imperial Aramaic (700-300 BCE)",
        "arg": "Aragonese",
        "arm": "Armenian",
        "arn": "Mapudungun; Mapuche",
        "arp": "Arapaho",
        "art": "Artificial languages",
        "arw": "Arawak",
        "asm": "Assamese",
        "ast": "Asturian; Bable; Leonese; Asturleonese",
        "ath": "Athapascan languages",
        "aus": "Australian languages",
        "ava": "Avaric",
        "ave": "Avestan",
        "awa": "Awadhi",
        "aym": "Aymara",
        "aze": "Azerbaijani",
        "bad": "Banda languages",
        "bai": "Bamileke languages",
        "bak": "Bashkir",
        "bal": "Baluchi",
        "bam": "Bambara",
        "ban": "Balinese",
        "baq": "Basque",
        "bas": "Basa",
        "bat": "Baltic languages",
        "bej": "Beja; Bedawiyet",
        "bel": "Belarusian",
        "bem": "Bemba",
        "ben": "Bengali",
        "ber": "Berber languages",
        "bho": "Bhojpuri",
        "bih": "Bihari languages",
        "bik": "Bikol",
        "bin": "Bini; Edo",
        "bis": "Bislama",
        "bla": "Siksika",
        "bnt": "Bantu (Other)",
        "bos": "Bosnian",
        "bra": "Braj",
        "bre": "Breton",
        "btk": "Batak languages",
        "bua": "Buriat",
        "bug": "Buginese",
        "bul": "Bulgarian",
        "bur": "Burmese",
        "byn": "Blin; Bilin",
        "cad": "Caddo",
        "cai": "Central American Indian languages",
        "car": "Galibi Carib",
        "cat": "Catalan; Valencian",
        "cau": "Caucasian languages",
        "ceb": "Cebuano",
        "cel": "Celtic languages",
        "cha": "Chamorro",
        "chb": "Chibcha",
        "che": "Chechen",
        "chg": "Chagatai",
        "chi": "Chinese",
        "chk": "Chuukese",
        "chm": "Mari",
        "chn": "Chinook jargon",
        "cho": "Choctaw",
        "chp": "Chipewyan; Dene Suline",
        "chr": "Cherokee",
        "chu": "Church Slavic; Old Slavonic; Church Slavonic; Old Bulgarian; Old Church Slavonic",
        "chv": "Chuvash",
        "chy": "Cheyenne",
        "cmc": "Chamic languages",
        "cop": "Coptic",
        "cor": "Cornish",
        "cos": "Corsican",
        "cpe": "Creoles and pidgins, English based",
        "cpf": "Creoles and pidgins, French-based ",
        "cpp": "Creoles and pidgins, Portuguese-based ",
        "cre": "Cree",
        "crh": "Crimean Tatar; Crimean Turkish",
        "crp": "Creoles and pidgins ",
        "csb": "Kashubian",
        "cus": "Cushitic languages",
        "cze": "Czech",
        "dak": "Dakota",
        "dan": "Danish",
        "dar": "Dargwa",
        "day": "Land Dayak languages",
        "del": "Delaware",
        "den": "Slave (Athapascan)",
        "dgr": "Dogrib",
        "din": "Dinka",
        "div": "Divehi; Dhivehi; Maldivian",
        "doi": "Dogri",
        "dra": "Dravidian languages",
        "dsb": "Lower Sorbian",
        "dua": "Duala",
        "dum": "Dutch, Middle (ca.1050-1350)",
        "dut": "Dutch; Flemish",
        "dyu": "Dyula",
        "dzo": "Dzongkha",
        "efi": "Efik",
        "egy": "Egyptian (Ancient)",
        "eka": "Ekajuk",
        "elx": "Elamite",
        "eng": "English",
        "enm": "English, Middle (1100-1500)",
        "epo": "Esperanto",
        "est": "Estonian",
        "ewe": "Ewe",
        "ewo": "Ewondo",
        "fan": "Fang",
        "fao": "Faroese",
        "fat": "Fanti",
        "fij": "Fijian",
        "fil": "Filipino; Pilipino",
        "fin": "Finnish",
        "fiu": "Finno-Ugrian languages",
        "fon": "Fon",
        "fre": "French",
        "frm": "French, Middle (ca.1400-1600)",
        "fro": "French, Old (842-ca.1400)",
        "frc": "French (Canada)",
        "frr": "Northern Frisian",
        "frs": "Eastern Frisian",
        "fry": "Western Frisian",
        "ful": "Fulah",
        "fur": "Friulian",
        "gaa": "Ga",
        "gay": "Gayo",
        "gba": "Gbaya",
        "gem": "Germanic languages",
        "geo": "Georgian",
        "ger": "German",
        "gez": "Geez",
        "gil": "Gilbertese",
        "gla": "Gaelic; Scottish Gaelic",
        "gle": "Irish",
        "glg": "Galician",
        "glv": "Manx",
        "gmh": "German, Middle High (ca.1050-1500)",
        "goh": "German, Old High (ca.750-1050)",
        "gon": "Gondi",
        "gor": "Gorontalo",
        "got": "Gothic",
        "grb": "Grebo",
        "grc": "Greek, Ancient (to 1453)",
        "gre": "Greek, Modern (1453-)",
        "grn": "Guarani",
        "gsw": "Swiss German; Alemannic; Alsatian",
        "guj": "Gujarati",
        "gwi": "Gwich'in",
        "hai": "Haida",
        "hat": "Haitian; Haitian Creole",
        "hau": "Hausa",
        "haw": "Hawaiian",
        "heb": "Hebrew",
        "her": "Herero",
        "hil": "Hiligaynon",
        "him": "Himachali languages; Western Pahari languages",
        "hin": "Hindi",
        "hit": "Hittite",
        "hmn": "Hmong; Mong",
        "hmo": "Hiri Motu",
        "hrv": "Croatian",
        "hsb": "Upper Sorbian",
        "hun": "Hungarian",
        "hup": "Hupa",
        "iba": "Iban",
        "ibo": "Igbo",
        "ice": "Icelandic",
        "ido": "Ido",
        "iii": "Sichuan Yi; Nuosu",
        "ijo": "Ijo languages",
        "iku": "Inuktitut",
        "ile": "Interlingue; Occidental",
        "ilo": "Iloko",
        "ina": "Interlingua (International Auxiliary Language Association)",
        "inc": "Indic languages",
        "ind": "Indonesian",
        "ine": "Indo-European languages",
        "inh": "Ingush",
        "ipk": "Inupiaq",
        "ira": "Iranian languages",
        "iro": "Iroquoian languages",
        "ita": "Italian",
        "jav": "Javanese",
        "jbo": "Lojban",
        "jpn": "Japanese",
        "jpr": "Judeo-Persian",
        "jrb": "Judeo-Arabic",
        "kaa": "Kara-Kalpak",
        "kab": "Kabyle",
        "kac": "Kachin; Jingpho",
        "kal": "Kalaallisut; Greenlandic",
        "kam": "Kamba",
        "kan": "Kannada",
        "kar": "Karen languages",
        "kas": "Kashmiri",
        "kau": "Kanuri",
        "kaw": "Kawi",
        "kaz": "Kazakh",
        "kbd": "Kabardian",
        "kha": "Khasi",
        "khi": "Khoisan languages",
        "khm": "Central Khmer",
        "kho": "Khotanese; Sakan",
        "kik": "Kikuyu; Gikuyu",
        "kin": "Kinyarwanda",
        "kir": "Kirghiz; Kyrgyz",
        "kmb": "Kimbundu",
        "kok": "Konkani",
        "kom": "Komi",
        "kon": "Kongo",
        "kor": "Korean",
        "kos": "Kosraean",
        "kpe": "Kpelle",
        "krc": "Karachay-Balkar",
        "krl": "Karelian",
        "kro": "Kru languages",
        "kru": "Kurukh",
        "kua": "Kuanyama; Kwanyama",
        "kum": "Kumyk",
        "kur": "Kurdish",
        "kut": "Kutenai",
        "lad": "Ladino",
        "lah": "Lahnda",
        "lam": "Lamba",
        "lao": "Lao",
        "lat": "Latin",
        "lav": "Latvian",
        "lez": "Lezghian",
        "lim": "Limburgan; Limburger; Limburgish",
        "lin": "Lingala",
        "lit": "Lithuanian",
        "lol": "Mongo",
        "loz": "Lozi",
        "ltz": "Luxembourgish; Letzeburgesch",
        "lua": "Luba-Lulua",
        "lub": "Luba-Katanga",
        "lug": "Ganda",
        "lui": "Luiseno",
        "lun": "Lunda",
        "luo": "Luo (Kenya and Tanzania)",
        "lus": "Lushai",
        "mac": "Macedonian",
        "mad": "Madurese",
        "mag": "Magahi",
        "mah": "Marshallese",
        "mai": "Maithili",
        "mak": "Makasar",
        "mal": "Malayalam",
        "man": "Mandingo",
        "mao": "Maori",
        "map": "Austronesian languages",
        "mar": "Marathi",
        "mas": "Masai",
        "may": "Malay",
        "mdf": "Moksha",
        "mdr": "Mandar",
        "men": "Mende",
        "mga": "Irish, Middle (900-1200)",
        "mic": "Mi'kmaq; Micmac",
        "min": "Minangkabau",
        "mis": "Uncoded languages",
        "mkh": "Mon-Khmer languages",
        "mlg": "Malagasy",
        "mlt": "Maltese",
        "mnc": "Manchu",
        "mni": "Manipuri",
        "mno": "Manobo languages",
        "moh": "Mohawk",
        "mon": "Mongolian",
        "mos": "Mossi",
        "mul": "Multiple languages",
        "mun": "Munda languages",
        "mus": "Creek",
        "mwl": "Mirandese",
        "mwr": "Marwari",
        "myn": "Mayan languages",
        "myv": "Erzya",
        "nah": "Nahuatl languages",
        "nai": "North American Indian languages",
        "nap": "Neapolitan",
        "nau": "Nauru",
        "nav": "Navajo; Navaho",
        "nbl": "Ndebele, South; South Ndebele",
        "nde": "Ndebele, North; North Ndebele",
        "ndo": "Ndonga",
        "nds": "Low German; Low Saxon; German, Low; Saxon, Low",
        "nep": "Nepali",
        "new": "Nepal Bhasa; Newari",
        "nia": "Nias",
        "nic": "Niger-Kordofanian languages",
        "niu": "Niuean",
        "nno": "Norwegian Nynorsk; Nynorsk, Norwegian",
        "nob": "Bokmål, Norwegian; Norwegian Bokmål",
        "nog": "Nogai",
        "non": "Norse, Old",
        "nor": "Norwegian",
        "nqo": "N'Ko",
        "nso": "Pedi; Sepedi; Northern Sotho",
        "nub": "Nubian languages",
        "nwc": "Classical Newari; Old Newari; Classical Nepal Bhasa",
        "nya": "Chichewa; Chewa; Nyanja",
        "nym": "Nyamwezi",
        "nyn": "Nyankole",
        "nyo": "Nyoro",
        "nzi": "Nzima",
        "oci": "Occitan (post 1500); Provençal",
        "oji": "Ojibwa",
        "ori": "Oriya",
        "orm": "Oromo",
        "osa": "Osage",
        "oss": "Ossetian; Ossetic",
        "ota": "Turkish, Ottoman (1500-1928)",
        "oto": "Otomian languages",
        "paa": "Papuan languages",
        "pag": "Pangasinan",
        "pal": "Pahlavi",
        "pam": "Pampanga; Kapampangan",
        "pan": "Panjabi; Punjabi",
        "pap": "Papiamento",
        "pau": "Palauan",
        "peo": "Persian, Old (ca.600-400 B.C.)",
        "per": "Persian",
        "phi": "Philippine languages",
        "phn": "Phoenician",
        "pli": "Pali",
        "pol": "Polish",
        "pon": "Pohnpeian",
        "por": "Portuguese",
        "pob": "Portuguese (Brazil)",
        "pra": "Prakrit languages",
        "pro": "Provençal, Old (to 1500)",
        "pus": "Pushto; Pashto",
        "qaa-qtz": "Reserved for local use",
        "que": "Quechua",
        "raj": "Rajasthani",
        "rap": "Rapanui",
        "rar": "Rarotongan; Cook Islands Maori",
        "roa": "Romance languages",
        "roh": "Romansh",
        "rom": "Romany",
        "rum": "Romanian; Moldavian; Moldovan",
        "run": "Rundi",
        "rup": "Aromanian; Arumanian; Macedo-Romanian",
        "rus": "Russian",
        "sad": "Sandawe",
        "sag": "Sango",
        "sah": "Yakut",
        "sai": "South American Indian (Other)",
        "sal": "Salishan languages",
        "sam": "Samaritan Aramaic",
        "san": "Sanskrit",
        "sas": "Sasak",
        "sat": "Santali",
        "scn": "Sicilian",
        "sco": "Scots",
        "sel": "Selkup",
        "sem": "Semitic languages",
        "sga": "Irish, Old (to 900)",
        "sgn": "Sign Languages",
        "shn": "Shan",
        "sid": "Sidamo",
        "sin": "Sinhala; Sinhalese",
        "sio": "Siouan languages",
        "sit": "Sino-Tibetan languages",
        "sla": "Slavic languages",
        "slo": "Slovak",
        "slv": "Slovenian",
        "sma": "Southern Sami",
        "sme": "Northern Sami",
        "smi": "Sami languages",
        "smj": "Lule Sami",
        "smn": "Inari Sami",
        "smo": "Samoan",
        "sms": "Skolt Sami",
        "sna": "Shona",
        "snd": "Sindhi",
        "snk": "Soninke",
        "sog": "Sogdian",
        "som": "Somali",
        "son": "Songhai languages",
        "sot": "Sotho, Southern",
        "spa": "Spanish; Latin",
        "spa": "Spanish; Castilian",
        "srd": "Sardinian",
        "srn": "Sranan Tongo",
        "srp": "Serbian",
        "srr": "Serer",
        "ssa": "Nilo-Saharan languages",
        "ssw": "Swati",
        "suk": "Sukuma",
        "sun": "Sundanese",
        "sus": "Susu",
        "sux": "Sumerian",
        "swa": "Swahili",
        "swe": "Swedish",
        "syc": "Classical Syriac",
        "syr": "Syriac",
        "tah": "Tahitian",
        "tai": "Tai languages",
        "tam": "Tamil",
        "tat": "Tatar",
        "tel": "Telugu",
        "tem": "Timne",
        "ter": "Tereno",
        "tet": "Tetum",
        "tgk": "Tajik",
        "tgl": "Tagalog",
        "tha": "Thai",
        "tib": "Tibetan",
        "tig": "Tigre",
        "tir": "Tigrinya",
        "tiv": "Tiv",
        "tkl": "Tokelau",
        "tlh": "Klingon; tlhIngan-Hol",
        "tli": "Tlingit",
        "tmh": "Tamashek",
        "tog": "Tonga (Nyasa)",
        "ton": "Tonga (Tonga Islands)",
        "tpi": "Tok Pisin",
        "tsi": "Tsimshian",
        "tsn": "Tswana",
        "tso": "Tsonga",
        "tuk": "Turkmen",
        "tum": "Tumbuka",
        "tup": "Tupi languages",
        "tur": "Turkish",
        "tut": "Altaic languages",
        "tvl": "Tuvalu",
        "twi": "Twi",
        "tyv": "Tuvinian",
        "udm": "Udmurt",
        "uga": "Ugaritic",
        "uig": "Uighur; Uyghur",
        "ukr": "Ukrainian",
        "umb": "Umbundu",
        "und": "Undetermined",
        "urd": "Urdu",
        "uzb": "Uzbek",
        "vai": "Vai",
        "ven": "Venda",
        "vie": "Vietnamese",
        "vol": "Volapük",
        "vot": "Votic",
        "wak": "Wakashan languages",
        "wal": "Walamo",
        "war": "Waray",
        "was": "Washo",
        "wel": "Welsh",
        "wen": "Sorbian languages",
        "wln": "Walloon",
        "wol": "Wolof",
        "xal": "Kalmyk; Oirat",
        "xho": "Xhosa",
        "yao": "Yao",
        "yap": "Yapese",
        "yid": "Yiddish",
        "yor": "Yoruba",
        "ypk": "Yupik languages",
        "zap": "Zapotec",
        "zbl": "Blissymbols; Blissymbolics; Bliss",
        "zen": "Zenaga",
        "zgh": "Standard Moroccan Tamazight",
        "zha": "Zhuang; Chuang",
        "znd": "Zande languages",
        "zul": "Zulu",
        "zun": "Zuni",
        "zxx": "No linguistic content; Not applicable",
        "zza": "Zaza; Dimili; Dimli; Kirdki; Kirmanjki; Zazaki"
    }
end function

function CreateSeasonDetailsGroup(series, season)
    group = CreateObject("roSGNode", "TVEpisodes")
    group.optionsAvailable = false
    m.global.sceneManager.callFunc("pushScene", group)

    group.seasonData = ItemMetaData(season.id).json
    group.objects = TVEpisodes(series.id, season.id)

    group.observeField("episodeSelected", m.port)
    group.observeField("quickPlayNode", m.port)

    return group
end function

function PlayIntroVideo(video_id, audio_stream_idx) as boolean
    ' Intro videos only play if user has cinema mode setting enabled
    if get_user_setting("playback.cinemamode") = "true"

        ' Check if server has intro videos setup and available
        introVideos = GetIntroVideos(video_id)

        if introVideos = invalid then return true

        if introVideos.TotalRecordCount > 0
            ' Bypass joke pre-roll
            if lcase(introVideos.items[0].name) = "rick roll'd" then return true

            introVideo = LoadItems_VideoPlayer(introVideos.items[0].id, introVideos.items[0].id, audio_stream_idx, defaultSubtitleTrackFromVid(video_id), false, false)

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

function CreateMovieDetailsGroup(movie)
    group = CreateObject("roSGNode", "MovieDetails")
    group.overhangTitle = movie.title
    group.optionsAvailable = false
    m.global.sceneManager.callFunc("pushScene", group)

    movie = ItemMetaData(movie.id)
    group.itemContent = movie
    group.trailerAvailable = false

    trailerData = api_API().users.getlocaltrailers(get_setting("active_user"), movie.id)
    if isValid(trailerData)
        group.trailerAvailable = trailerData.Count() > 0
    end if

    buttons = group.findNode("buttons")
    for each b in buttons.getChildren(-1, 0)
        b.observeField("buttonSelected", m.port)
    end for

    extras = group.findNode("extrasGrid")
    extras.observeField("selectedItem", m.port)
    extras.callFunc("loadParts", movie.json)

    return group
end function

function CreateSeriesDetailsGroup(series)
    ' Get season data early in the function so we can check number of seasons.
    seasonData = TVSeasons(series.id)
    ' Divert to season details if user setting goStraightToEpisodeListing is enabled and only one season exists.
    if get_user_setting("ui.tvshows.goStraightToEpisodeListing") = "true" and seasonData.Items.Count() = 1
        return CreateSeasonDetailsGroupByID(series.id, seasonData.Items[0].id)
    end if
    group = CreateObject("roSGNode", "TVShowDetails")
    group.optionsAvailable = false
    m.global.sceneManager.callFunc("pushScene", group)

    group.itemContent = ItemMetaData(series.id)
    group.seasonData = seasonData ' Re-use variable from beginning of function

    group.observeField("seasonSelected", m.port)

    extras = group.findNode("extrasGrid")
    extras.observeField("selectedItem", m.port)
    extras.callFunc("loadParts", group.itemcontent.json)

    return group
end function

function CreateSeasonDetailsGroupByID(seriesID, seasonID)
    group = CreateObject("roSGNode", "TVEpisodes")
    group.optionsAvailable = false
    m.global.sceneManager.callFunc("pushScene", group)

    group.seasonData = ItemMetaData(seasonID).json
    group.objects = TVEpisodes(seriesID, seasonID)

    group.observeField("episodeSelected", m.port)
    group.observeField("quickPlayNode", m.port)

    return group
end function
