import "pkg:/source/utils/config.brs"
import "pkg:/source/utils/misc.brs"
import "pkg:/source/utils/deviceCapabilities.brs"
import "pkg:/source/api/baserequest.brs"
import "pkg:/source/roku_modules/api/api.brs"

sub init()
    m.top.functionName = "getPlaybackInfoTask"
end sub

function ItemPostPlaybackInfo(id as string, mediaSourceId = "" as string, audioTrackIndex = -1 as integer, startTimeTicks = 0 as longinteger)
    currentView = m.global.sceneManager.callFunc("getActiveScene")
    currentItem = m.global.queueManager.callFunc("getCurrentItem")

    body = {
        "DeviceProfile": getDeviceProfile()
    }
    params = {
        "UserId": get_setting("active_user"),
        "StartTimeTicks": currentItem.startingPoint,
        "IsPlayback": true,
        "AutoOpenLiveStream": true,
        "MaxStreamingBitrate": "140000000",
        "MaxStaticBitrate": "140000000",
        "SubtitleStreamIndex": currentView.selectedSubtitle,
        "MediaSourceId": currentItem.id,
        "AudioStreamIndex": currentItem.selectedAudioStreamIndex
    }

    req = APIRequest(Substitute("Items/{0}/PlaybackInfo", id), params)
    req.SetRequest("POST")
    return postJson(req, FormatJson(body))
end function

' Returns an array of playback info to be displayed during playback.
' In the future, with a custom playback info view, we can return an associated array.
sub getPlaybackInfoTask()
    sessions = api_API().sessions.get()

    m.playbackInfo = ItemPostPlaybackInfo(m.top.videoID)

    if isValid(sessions) and sessions.Count() > 0
        m.top.data = { playbackInfo: GetTranscodingStats(sessions[0]) }
    else
        m.top.data = { playbackInfo: [tr("Unable to get playback information")] }
    end if
end sub

function GetTranscodingStats(session)
    sessionStats = { data: [] }

    if isValid(session.TranscodingInfo) and session.TranscodingInfo.Count() > 0
        transcodingReasons = session.TranscodingInfo.TranscodeReasons
        videoCodec = session.TranscodingInfo.VideoCodec
        audioCodec = session.TranscodingInfo.AudioCodec
        totalBitrate = session.TranscodingInfo.Bitrate
        audioChannels = session.TranscodingInfo.AudioChannels

        if isValid(transcodingReasons) and transcodingReasons.Count() > 0
            sessionStats.data.push("<header>" + tr("Transcoding Information") + "</header>")
            for each item in transcodingReasons
                sessionStats.data.push("<b>• " + tr("Reason") + ":</b> " + item)
            end for
        end if

        if isValid(videoCodec)
            data = "<b>• " + tr("Video Codec") + ":</b> " + videoCodec
            if session.TranscodingInfo.IsVideoDirect
                data = data + " (" + tr("direct") + ")"
            end if
            sessionStats.data.push(data)
        end if

        if isValid(audioCodec)
            data = "<b>• " + tr("Audio Codec") + ":</b> " + audioCodec
            if session.TranscodingInfo.IsAudioDirect
                data = data + " (" + tr("direct") + ")"
            end if
            sessionStats.data.push(data)
        end if

        if isValid(totalBitrate)
            data = "<b>• " + tr("Total Bitrate") + ":</b> " + getDisplayBitrate(totalBitrate)
            sessionStats.data.push(data)
        end if

        if isValid(audioChannels)
            data = "<b>• " + tr("Audio Channels") + ":</b> " + Str(audioChannels)
            sessionStats.data.push(data)
        end if
    end if

    if havePlaybackInfo()
        stream = m.playbackInfo.mediaSources[0].MediaStreams[0]
        sessionStats.data.push("<header>" + tr("Stream Information") + "</header>")
        if isValid(stream.Container)
            data = "<b>• " + tr("Container") + ":</b> " + stream.Container
            sessionStats.data.push(data)
        end if
        if isValid(stream.Size)
            data = "<b>• " + tr("Size") + ":</b> " + stream.Size
            sessionStats.data.push(data)
        end if
        if isValid(stream.BitRate)
            data = "<b>• " + tr("Bit Rate") + ":</b> " + getDisplayBitrate(stream.BitRate)
            sessionStats.data.push(data)
        end if
        if isValid(stream.Codec)
            data = "<b>• " + tr("Codec") + ":</b> " + stream.Codec
            sessionStats.data.push(data)
        end if
        if isValid(stream.CodecTag)
            data = "<b>• " + tr("Codec Tag") + ":</b> " + stream.CodecTag
            sessionStats.data.push(data)
        end if
        if isValid(stream.VideoRangeType)
            data = "<b>• " + tr("Video range type") + ":</b> " + stream.VideoRangeType
            sessionStats.data.push(data)
        end if
        if isValid(stream.PixelFormat)
            data = "<b>• " + tr("Pixel format") + ":</b> " + stream.PixelFormat
            sessionStats.data.push(data)
        end if
        if isValid(stream.Width) and isValid(stream.Height)
            data = "<b>• " + tr("WxH") + ":</b> " + Str(stream.Width) + " x " + Str(stream.Height)
            sessionStats.data.push(data)
        end if
        if isValid(stream.Level)
            data = "<b>• " + tr("Level") + ":</b> " + Str(stream.Level)
            sessionStats.data.push(data)
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
