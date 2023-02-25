'Device Capabilities for Roku.
'This will likely need further tweaking

function getDeviceCapabilities() as object

    return {
        "PlayableMediaTypes": [
            "Audio",
            "Video"
        ],
        "SupportedCommands": [],
        "SupportsPersistentIdentifier": false,
        "SupportsMediaControl": false,
        "DeviceProfile": getDeviceProfile()
    }
end function


function getDeviceProfile() as object
    playMpeg2 = get_user_setting("playback.mpeg2") = "true"
    playAv1 = get_user_setting("playback.av1") = "true"

    'Check if 5.1 Audio Output connected
    maxAudioChannels = 2
    di = CreateObject("roDeviceInfo")
    if di.GetAudioOutputChannel() = "5.1 surround"
        maxAudioChannels = 6
    end if

    addHevcProfile = false
    MAIN10 = ""
    tsVideoCodecs = "h264"
    if di.CanDecodeVideo({ Codec: "hevc" }).Result = true
        tsVideoCodecs = "h265,hevc," + tsVideoCodecs
        addHevcProfile = true
        if di.CanDecodeVideo({ Codec: "hevc", Profile: "main 10" }).Result
            MAIN10 = "|main 10"
        end if
    end if

    if playMpeg2 and di.CanDecodeVideo({ Codec: "mpeg2" }).Result = true
        tsVideoCodecs = tsVideoCodecs + ",mpeg2video"
    end if

    if di.CanDecodeAudio({ Codec: "ac3" }).result
        tsAudioCodecs = "aac,ac3"
    else
        tsAudioCodecs = "aac"
    end if

    addAv1Profile = false
    if playAv1 and di.CanDecodeVideo({ Codec: "av1" }).result
        tsVideoCodecs = tsVideoCodecs + ",av1"
        addAv1Profile = true
    end if

    addVp9Profile = false
    if di.CanDecodeVideo({ Codec: "vp9" }).result
        tsVideoCodecs = tsVideoCodecs + ",vp9"
        addVp9Profile = true
    end if

    hevcVideoRangeTypes = "SDR"
    vp9VideoRangeTypes = "SDR"
    av1VideoRangeTypes = "SDR"

    dp = di.GetDisplayProperties()
    if dp.Hdr10 ' or dp.Hdr10Plus?
        hevcVideoRangeTypes = hevcVideoRangeTypes + "|HDR10"
        vp9VideoRangeTypes = vp9VideoRangeTypes + "|HDR10"
        av1VideoRangeTypes = av1VideoRangeTypes + "|HDR10"
    end if
    if dp.HLG
        hevcVideoRangeTypes = hevcVideoRangeTypes + "|HLG"
        vp9VideoRangeTypes = vp9VideoRangeTypes + "|HLG"
        av1VideoRangeTypes = av1VideoRangeTypes + "|HLG"
    end if
    if dp.DolbyVision
        hevcVideoRangeTypes = hevcVideoRangeTypes + "|DOVI"
        'vp9VideoRangeTypes = vp9VideoRangeTypes + ",DOVI" no evidence that vp9 can hold DOVI
        av1VideoRangeTypes = av1VideoRangeTypes + "|DOVI"
    end if

    DirectPlayProfile = GetDirectPlayProfiles()

    deviceProfile = {
        "MaxStreamingBitrate": 120000000,
        "MaxStaticBitrate": 100000000,
        "MusicStreamingTranscodingBitrate": 192000,
        "DirectPlayProfiles": DirectPlayProfile,
        "TranscodingProfiles": [
            {
                "Container": "aac",
                "Type": "Audio",
                "AudioCodec": "aac",
                "Context": "Streaming",
                "Protocol": "http",
                "MaxAudioChannels": StrI(maxAudioChannels) ' Currently Jellyfin server expects this as a string
            },
            {
                "Container": "mp3",
                "Type": "Audio",
                "AudioCodec": "mp3",
                "Context": "Streaming",
                "Protocol": "http",
                "MaxAudioChannels": "2"
            },
            {
                "Container": "mp3",
                "Type": "Audio",
                "AudioCodec": "mp3",
                "Context": "Static",
                "Protocol": "http",
                "MaxAudioChannels": "2"
            },
            {
                "Container": "aac",
                "Type": "Audio",
                "AudioCodec": "aac",
                "Context": "Static",
                "Protocol": "http",
                "MaxAudioChannels": StrI(maxAudioChannels) ' Currently Jellyfin server expects this as a string
            },
            {
                "Container": "ts",
                "Type": "Video",
                "AudioCodec": tsAudioCodecs,
                "VideoCodec": tsVideoCodecs,
                "Context": "Streaming",
                "Protocol": "hls",
                "MaxAudioChannels": StrI(maxAudioChannels), ' Currently Jellyfin server expects this as a string
                "MinSegments": "1",
                "BreakOnNonKeyFrames": true
            },
            {
                "Container": "mp4",
                "Type": "Video",
                "AudioCodec": "aac,opus,flac,vorbis",
                "VideoCodec": "h264",
                "Context": "Static",
                "Protocol": "http"
            }
        ],
        "ContainerProfiles": [],
        "CodecProfiles": [
            {
                "Type": "VideoAudio",
                "Codec": DirectPlayProfile[1].AudioCodec, ' Use supported MKV Audio list
                "Conditions": [
                    {
                        "Condition": "LessThanEqual",
                        "Property": "AudioChannels",
                        "Value": StrI(maxAudioChannels), ' Currently Jellyfin server expects this as a string
                        "IsRequired": false
                    }
                ]
            },
            {
                "Type": "Video",
                "Codec": "h264",
                "Conditions": [
                    {
                        "Condition": "EqualsAny",
                        "Property": "VideoProfile",
                        "Value": "high|main",
                        "IsRequired": false
                    },
                    {
                        "Condition": "LessThanEqual",
                        "Property": "VideoLevel",
                        "Value": "41",
                        "IsRequired": false
                    },
                    GetBitRateLimit("H264")
                ]
            }
        ],
        "SubtitleProfiles": [
            {
                "Format": "vtt",
                "Method": "External"
            },
            {
                "Format": "srt",
                "Method": "External"
            },
            {
                "Format": "ttml",
                "Method": "External"
            },
            {
                "Format": "sub",
                "Method": "External"
            }
        ]
    }
    if addAv1Profile
        deviceProfile.CodecProfiles.push({
            "Type": "Video",
            "Codec": "av1",
            "Conditions": [
                {
                    "Condition": "EqualsAny",
                    "Property": "VideoRangeType",
                    "Value": av1VideoRangeTypes,
                    "IsRequired": false
                },
                GetBitRateLimit("AV1")
            ]
        })
    end if
    if addHevcProfile
        deviceProfile.CodecProfiles.push({
            "Type": "Video",
            "Codec": "hevc",
            "Conditions": [
                {
                    "Condition": "EqualsAny",
                    "Property": "VideoProfile",
                    "Value": "main" + MAIN10,
                    "IsRequired": false
                },
                {
                    "Condition": "EqualsAny",
                    "Property": "VideoRangeType",
                    "Value": hevcVideoRangeTypes,
                    "IsRequired": false
                },
                {
                    "Condition": "LessThanEqual",
                    "Property": "VideoLevel",
                    "Value": (120 * 5.1).ToStr(),
                    "IsRequired": false
                },
                GetBitRateLimit("H265")
            ]
        })
    end if
    if addVp9Profile
        deviceProfile.CodecProfiles.push({
            "Type": "Video",
            "Codec": "vp9",
            "Conditions": [
                {
                    "Condition": "EqualsAny",
                    "Property": "VideoRangeType",
                    "Value": vp9VideoRangeTypes,
                    "IsRequired": false
                },
                GetBitRateLimit("VP9")
            ]
        })
    end if

    return deviceProfile
end function


function GetDirectPlayProfiles() as object

    mp4Video = "h264"
    mp4Audio = "mp3,pcm,lpcm,wav"
    mkvVideo = "h264,vp8"
    mkvAudio = "mp3,pcm,lpcm,wav"
    audio = "mp3,pcm,lpcm,wav"

    playMpeg2 = get_user_setting("playback.mpeg2") = "true"

    di = CreateObject("roDeviceInfo")

    'Check for Supported Video Codecs
    if di.CanDecodeVideo({ Codec: "hevc" }).Result = true
        mp4Video = mp4Video + ",h265,hevc"
        mkvVideo = mkvVideo + ",h265,hevc"
    end if

    if di.CanDecodeVideo({ Codec: "vp9" }).Result = true
        mkvVideo = mkvVideo + ",vp9"
    end if

    if playMpeg2 and di.CanDecodeVideo({ Codec: "mpeg2" }).Result = true
        mp4Video = mp4Video + ",mpeg2video"
        mkvVideo = mkvVideo + ",mpeg2video"
    end if

    if get_user_setting("playback.mpeg4") = "true"
        mp4Video = mp4Video + ",mpeg4"
    end if

    ' Check for supported Audio
    if di.CanDecodeAudio({ Codec: "ac3" }).result
        mkvAudio = mkvAudio + ",ac3"
        mp4Audio = mp4Audio + ",ac3"
        audio = audio + ",ac3"
    end if

    if di.CanDecodeAudio({ Codec: "wma" }).result
        audio = audio + ",wma"
    end if

    if di.CanDecodeAudio({ Codec: "flac" }).result
        mkvAudio = mkvAudio + ",flac"
        audio = audio + ",flac"
    end if

    if di.CanDecodeAudio({ Codec: "alac" }).result
        mkvAudio = mkvAudio + ",alac"
        mp4Audio = mp4Audio + ",alac"
        audio = audio + ",alac"
    end if

    if di.CanDecodeAudio({ Codec: "aac" }).result
        mkvAudio = mkvAudio + ",aac"
        mp4Audio = mp4Audio + ",aac"
        audio = audio + ",aac"
    end if

    if di.CanDecodeAudio({ Codec: "opus" }).result
        mkvAudio = mkvAudio + ",opus"
    end if

    if di.CanDecodeAudio({ Codec: "dts" }).result
        mkvAudio = mkvAudio + ",dts"
        audio = audio + ",dts"
    end if

    if di.CanDecodeAudio({ Codec: "wmapro" }).result
        audio = audio + ",wmapro"
    end if

    if di.CanDecodeAudio({ Codec: "vorbis" }).result
        mkvAudio = mkvAudio + ",vorbis"
    end if

    if di.CanDecodeAudio({ Codec: "eac3" }).result
        mkvAudio = mkvAudio + ",eac3"
        mp4Audio = mp4Audio + ",eac3"
        audio = audio + ",eac3"
    end if

    return [
        {
            "Container": "mp4,m4v,mov",
            "Type": "Video",
            "VideoCodec": mp4Video,
            "AudioCodec": mp4Audio
        },
        {
            "Container": "mkv,webm",
            "Type": "Video",
            "VideoCodec": mkvVideo,
            "AudioCodec": mkvAudio
        },
        {
            "Container": audio,
            "Type": "Audio"
        }
    ]

end function

function GetBitRateLimit(codec as string)
    if get_user_setting("playback.bitrate.maxlimited") = "true"
        userSetLimit = get_user_setting("playback.bitrate.limit").ToInt()
        userSetLimit *= 1000000

        if userSetLimit > 0
            return {
                "Condition": "LessThanEqual",
                "Property": "VideoBitrate",
                "Value": userSetLimit.ToStr(),
                IsRequired: true
            }
        else
            ' Some repeated values (e.g. same "40mbps" for several codecs)
            ' but this makes it easy to update in the future if the bitrates start to deviate.
            if codec = "H264"
                ' Roku only supports h264 up to 10Mpbs
                return {
                    "Condition": "LessThanEqual",
                    "Property": "VideoBitrate",
                    "Value": "10000000",
                    IsRequired: true
                }
            else if codec = "AV1"
                ' Roku only supports AV1 up to 40Mpbs
                return {
                    "Condition": "LessThanEqual",
                    "Property": "VideoBitrate",
                    "Value": "40000000",
                    IsRequired: true
                }
            else if codec = "H265"
                ' Roku only supports h265 up to 40Mpbs
                return {
                    "Condition": "LessThanEqual",
                    "Property": "VideoBitrate",
                    "Value": "40000000",
                    IsRequired: true
                }
            else if codec = "VP9"
                ' Roku only supports VP9 up to 40Mpbs
                return {
                    "Condition": "LessThanEqual",
                    "Property": "VideoBitrate",
                    "Value": "40000000",
                    IsRequired: true
                }
            end if
        end if
    end if
    return {}
end function
