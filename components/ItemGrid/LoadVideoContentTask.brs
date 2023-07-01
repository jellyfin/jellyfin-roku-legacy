import "pkg:/source/utils/misc.brs"
import "pkg:/source/api/Items.brs"
import "pkg:/source/api/UserLibrary.brs"
import "pkg:/source/api/baserequest.brs"
import "pkg:/source/utils/config.brs"
import "pkg:/source/api/Image.brs"
import "pkg:/source/api/userauth.brs"
import "pkg:/source/utils/deviceCapabilities.brs"

sub init()
    m.user = AboutMe()
    m.top.functionName = "loadItems"
end sub

sub loadItems()
    ' Reset intro tracker in case task gets reused
    m.top.isIntro = false

    ' Only show preroll once per queue
    if m.global.queueManager.callFunc("isPrerollActive")
        ' Prerolls not allowed if we're resuming video
        if m.global.queueManager.callFunc("getCurrentItem").startingPoint = 0
            preRoll = GetIntroVideos(m.top.itemId)
            if isValid(preRoll) and preRoll.TotalRecordCount > 0 and isValid(preRoll.items[0])
                ' If an error is thrown in the Intros plugin, instead of passing the error they pass the entire rick roll music video.
                ' Bypass the music video and treat it as an error message
                if lcase(preRoll.items[0].name) <> "rick roll'd"
                    m.global.queueManager.callFunc("push", m.global.queueManager.callFunc("getCurrentItem"))
                    m.top.itemId = preRoll.items[0].id
                    m.global.queueManager.callFunc("setPrerollStatus", false)
                    m.top.isIntro = true
                end if
            end if
        end if
    end if

    if m.top.selectedAudioStreamIndex = 0
        currentItem = m.global.queueManager.callFunc("getCurrentItem")
        if isValid(currentItem) and isValid(currentItem.json)
            m.top.selectedAudioStreamIndex = FindPreferredAudioStream(currentItem.json.MediaStreams)
        end if
    end if

    id = m.top.itemId
    mediaSourceId = invalid
    audio_stream_idx = m.top.selectedAudioStreamIndex
    subtitle_idx = m.top.selectedSubtitleIndex
    forceTranscoding = false

    m.top.content = [LoadItems_VideoPlayer(id, mediaSourceId, audio_stream_idx, subtitle_idx, forceTranscoding)]
end sub

function LoadItems_VideoPlayer(id as string, mediaSourceId = invalid as dynamic, audio_stream_idx = 1 as integer, subtitle_idx = -1 as integer, forceTranscoding = false as boolean) as dynamic

    video = {}
    video.id = id
    video.content = createObject("RoSGNode", "ContentNode")

    LoadItems_AddVideoContent(video, mediaSourceId, audio_stream_idx, subtitle_idx, forceTranscoding)

    if video.content = invalid
        return invalid
    end if

    return video
end function

sub LoadItems_AddVideoContent(video as object, mediaSourceId as dynamic, audio_stream_idx = 1 as integer, subtitle_idx = -1 as integer, forceTranscoding = false as boolean)

    meta = ItemMetaData(video.id)

    if not isValid(meta)
        video.errorMsg = "Error loading metadata"
        video.content = invalid
        return
    end if

    videotype = LCase(meta.type)

    if videotype = "episode" or videotype = "series"
        video.content.contenttype = "episode"
    end if

    video.content.title = meta.title
    video.showID = meta.showID

    user = AboutMe()
    if user.Configuration.EnableNextEpisodeAutoPlay
        if LCase(m.top.itemType) = "episode"
            addNextEpisodesToQueue(video.showID)
        end if
    end if

    playbackPosition = 0!

    currentItem = m.global.queueManager.callFunc("getCurrentItem")

    if isValid(currentItem) and isValid(currentItem.startingPoint)
        playbackPosition = currentItem.startingPoint
    end if

    ' PlayStart requires the time to be in seconds
    video.content.PlayStart = int(playbackPosition / 10000000)

    if not isValid(mediaSourceId) then mediaSourceId = video.id
    if meta.live then mediaSourceId = ""

    m.playbackInfo = ItemPostPlaybackInfo(video.id, mediaSourceId, audio_stream_idx, subtitle_idx, playbackPosition)
    video.videoId = video.id
    video.mediaSourceId = mediaSourceId
    video.audioIndex = audio_stream_idx

    if not isValid(m.playbackInfo)
        video.errorMsg = "Error loading playback info"
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
        tryDirectPlay = m.global.session.user.settings["playback.tryDirect.h264ProfileLevel"] and m.playbackInfo.MediaSources[0].MediaStreams[0].codec = "h264"
        tryDirectPlay = tryDirectPlay or (m.global.session.user.settings["playback.tryDirect.hevcProfileLevel"] and m.playbackInfo.MediaSources[0].MediaStreams[0].codec = "hevc")
        if tryDirectPlay and isValid(m.playbackInfo.MediaSources[0].TranscodingUrl) and forceTranscoding = false
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
            video.errorMsg = "Error getting playback information"
            video.content = invalid
            return
        end if
        ' Get transcoding reason
        video.transcodeReasons = getTranscodeReasons(m.playbackInfo.MediaSources[0].TranscodingUrl)
        video.content.url = buildURL(m.playbackInfo.MediaSources[0].TranscodingUrl)
        video.isTranscoded = true
    end if

    setCertificateAuthority(video.content)
    video.audioTrack = (audio_stream_idx + 1).ToStr() ' Roku's track indexes count from 1. Our index is zero based

    video.SelectedSubtitle = subtitle_idx

    if not fully_external
        video.content = authorize_request(video.content)
    end if

end sub

sub addVideoContentURL(video, mediaSourceId, audio_stream_idx, fully_external)
    protocol = LCase(m.playbackInfo.MediaSources[0].Protocol)
    if protocol <> "file"
        uri = parseUrl(m.playbackInfo.MediaSources[0].Path)
        if isLocalhost(uri[2])
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
    safesubs = subtitles["all"]
    subtitleTracks = []

    if m.global.session.user.settings["playback.subs.onlytext"] = true
        safesubs = subtitles["text"]
    end if

    for each subtitle in safesubs
        subtitleTracks.push(subtitle.track)
    end for

    video.content.SubtitleTracks = subtitleTracks
    video.fullSubtitleData = safesubs
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

function directPlaySupported(meta as object) as boolean
    devinfo = CreateObject("roDeviceInfo")
    if isValid(meta.json.MediaSources[0]) and meta.json.MediaSources[0].SupportsDirectPlay = false
        return false
    end if

    if meta.json.MediaStreams[0] = invalid
        return false
    end if

    streamInfo = { Codec: meta.json.MediaStreams[0].codec }
    if isValid(meta.json.MediaStreams[0].Profile) and meta.json.MediaStreams[0].Profile.len() > 0
        streamInfo.Profile = LCase(meta.json.MediaStreams[0].Profile)
    end if
    if isValid(meta.json.MediaSources[0].container) and meta.json.MediaSources[0].container.len() > 0
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

' Add next episodes to the playback queue
sub addNextEpisodesToQueue(showID)
    ' Don't queue next episodes if we already have a playback queue
    maxQueueCount = 1

    if m.top.isIntro
        maxQueueCount = 2
    end if

    if m.global.queueManager.callFunc("getCount") > maxQueueCount then return

    videoID = m.top.itemId

    ' If first item is an intro video, use the next item in the queue
    if m.top.isIntro
        currentVideo = m.global.queueManager.callFunc("getItemByIndex", 1)

        if isValid(currentVideo) and isValid(currentVideo.id)
            videoID = currentVideo.id

            ' Override showID value since it's for the intro video
            meta = ItemMetaData(videoID)
            if isValid(meta)
                showID = meta.showID
            end if
        end if
    end if

    url = Substitute("Shows/{0}/Episodes", showID)
    urlParams = { "UserId": m.global.session.user.id }
    urlParams.Append({ "StartItemId": videoID })
    urlParams.Append({ "Limit": 50 })
    resp = APIRequest(url, urlParams)
    data = getJson(resp)

    if isValid(data) and data.Items.Count() > 1
        for i = 1 to data.Items.Count() - 1
            m.global.queueManager.callFunc("push", data.Items[i])
        end for
    end if
end sub

'Checks available subtitle tracks and puts subtitles in forced, default, and non-default/forced but preferred language at the top
function sortSubtitles(id as string, MediaStreams)
    tracks = { "forced": [], "default": [], "normal": [], "text": [] }
    'Too many args for using substitute
    prefered_lang = m.global.session.user.configuration.SubtitleLanguagePreference
    for each stream in MediaStreams
        if stream.type = "Subtitle"

            url = ""
            if isValid(stream.DeliveryUrl)
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
            else if stream.IsTextSubtitleStream
                trackType = "text"
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
    tracks["forced"].append(tracks["text"])

    return { "all": tracks["forced"], "text": tracks["text"] }
end function

function FindPreferredAudioStream(streams as dynamic) as integer
    preferredLanguage = m.user.Configuration.AudioLanguagePreference
    playDefault = m.user.Configuration.PlayDefaultAudioTrack

    if playDefault <> invalid and playDefault = true
        return 1
    end if

    ' Do we already have the MediaStreams or not?
    if streams = invalid
        url = Substitute("Users/{0}/Items/{1}", m.user.id, m.top.itemId)
        resp = APIRequest(url)
        jsonResponse = getJson(resp)

        if jsonResponse = invalid or jsonResponse.MediaStreams = invalid then return 1

        streams = jsonResponse.MediaStreams
    end if

    if preferredLanguage <> invalid
        for i = 0 to streams.Count() - 1
            if LCase(streams[i].Type) = "audio" and LCase(streams[i].Language) = LCase(preferredLanguage)
                return i
            end if
        end for
    end if

    return 1
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
