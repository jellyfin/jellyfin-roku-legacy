function AudioPlayer(id, mediaSourceId = invalid, audio_stream_idx = 1, subtitle_idx = -1)

    ' Get video controls and UI
    audio = CreateObject("roSGNode", "JFAudio")
    audio.id = id
    AddAudioContent(audio, mediaSourceId, audio_stream_idx, subtitle_idx)

    if audio.content = invalid
        return invalid
    end if

    audio.control = "stop"
    audio.control = "none"
    audio.control = "play"

    return audio
end function

sub AddAudioContent(video, mediaSourceId, audio_stream_idx = 1, subtitle_idx = -1, playbackPosition = -1)

    video.content = createObject("RoSGNode", "ContentNode")
    meta = ItemMetaData(video.id)

    m.videotype = meta.type
    if meta = invalid
        video.content = invalid
        return
    end if

    ' Special handling for "Programs" launched from "On Now"
    if meta.json.type = "Program"
        meta.title = meta.json.EpisodeTitle
        meta.showID = meta.json.id
        meta.live = true
        video.id = meta.json.ChannelId
    end if

    video.content.title = meta.title
    video.showID = meta.showID

    playbackPosition = 0

    video.content.PlayStart = int(playbackPosition / 10000000)

    video.videoId = video.id

    params = {}

    ' video.container = getAudioContainerType(meta)
    video.streamformat = "mp3"


    ' video.directPlaySupported = playbackInfo.MediaSources[0].SupportsDirectPlay
    video.directPlaySupported = true
    fully_external = false

    ' protocol = LCase(playbackInfo.MediaSources[0].Protocol)
    protocol = "file"
    if protocol <> "file"
        uriRegex = CreateObject("roRegex", "^(.*:)//([A-Za-z0-9\-\.]+)(:[0-9]+)?(.*)$", "")
        ' uri = uriRegex.Match(playbackinfo.MediaSources[0].Path)
        uri = uriRegex.Match("")
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
            ' video.content.url = playbackinfo.MediaSources[0].Path
            video.content.url = ""
        end if
    else:
        video.content.url = buildURL(Substitute("Audio/{0}/stream", video.id))
    end if

    video.content.setCertificatesFile("common:/certs/ca-bundle.crt")

    if not fully_external
        video.content = authorize_request(video.content)
    end if

end sub

function getAudioContainerType(meta as object) as string
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