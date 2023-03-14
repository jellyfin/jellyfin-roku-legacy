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
    if isValid(meta) and isValid(meta.json) and isValid(meta.json.mediaSources)
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

function selectSubtitleTrack(tracks, current = -1) as integer
    video = m.scene.focusedChild.focusedChild
    trackSelected = selectSubtitleTrackDialog(video.Subtitles, video.SelectedSubtitle)
    if trackSelected = invalid or trackSelected = -1 ' back pressed in Dialog - no selection made
        return -2
    else
        return trackSelected - 1
    end if
end function

' Present Dialog to user to select subtitle track
function selectSubtitleTrackDialog(tracks, currentTrack = -1)
    iso6392 = getSubtitleLanguages()
    options = ["None"]
    for each item in tracks
        forced = ""
        default = ""
        if item.IsForced then forced = " [Forced]"
        if item.IsDefault then default = " - Default"
        if isValid(item.Track.Language)
            language = iso6392.lookup(item.Track.Language)
            if language = invalid then language = item.Track.Language
        else
            language = "Undefined"
        end if
        options.push(language + forced + default)
    end for
    return option_dialog(options, "Select a subtitle track", currentTrack + 1)
end function

sub changeSubtitleDuringPlayback(newid)

    ' If no subtitles set
    if newid = invalid or newid = -1
        turnoffSubtitles()
        return
    end if

    video = m.scene.focusedChild.focusedChild

    ' If no change of subtitle track, return
    if newid = video.SelectedSubtitle then return

    currentSubtitles = video.Subtitles[video.SelectedSubtitle]
    newSubtitles = video.Subtitles[newid]

    if newSubtitles.IsEncoded or (isValid(currentSubtitles) and currentSubtitles.IsEncoded)
        ' With encoded subtitles we need to stop/start playback
        video.control = "stop"
        AddVideoContent(video, video.mediaSourceId, video.audioIndex, newSubtitles.Index, video.position * 10000000)
        video.control = "play"
    else
        ' Switching from text to text (or none to text) does not require stopping playback
        video.globalCaptionMode = "On"
        video.subtitleTrack = video.availableSubtitleTracks[availSubtitleTrackIdx(video, newid)].TrackName
    end if

    video.SelectedSubtitle = newid

end sub

sub turnoffSubtitles()
    video = m.scene.focusedChild.focusedChild
    current = video.SelectedSubtitle
    video.SelectedSubtitle = -1
    video.globalCaptionMode = "Off"
    m.device.EnableAppFocusEvent(false)
    ' Check if Enoded subtitles are being displayed, and turn off
    if current > -1 and video.Subtitles[current].IsEncoded
        video.control = "stop"
        AddVideoContent(video, video.mediaSourceId, video.audioIndex, -1, video.position * 10000000)
        video.control = "play"
    end if
end sub

'Checks available subtitle tracks and puts subtitles in forced, default, and non-default/forced but preferred language at the top
function sortSubtitles(id as string, MediaStreams)
    tracks = { "forced": [], "default": [], "normal": [] }
    'Too many args for using substitute
    prefered_lang = m.user.Configuration.SubtitleLanguagePreference
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
