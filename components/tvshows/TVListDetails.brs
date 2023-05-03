sub init()
    m.title = m.top.findNode("title")
    m.title.text = tr("Loading...")
    m.options = m.top.findNode("tvListOptions")
    m.overview = m.top.findNode("overview")
    m.poster = m.top.findNode("poster")

    m.rating = m.top.findnode("rating")
    m.infoBar = m.top.findnode("infoBar")
    m.progressBackground = m.top.findNode("progressBackground")
    m.progressBar = m.top.findnode("progressBar")
    m.playedIndicator = m.top.findNode("playedIndicator")
    m.checkmark = m.top.findNode("checkmark")
    m.checkmark.font.size = 35
end sub

sub itemContentChanged()
    item = m.top.itemContent
    itemData = item.json
    if isValid(itemData.indexNumber)
        indexNumber = itemData.indexNumber.toStr() + ". "
    else
        indexNumber = ""
    end if
    m.title.text = indexNumber + item.title
    m.overview.text = item.overview

    if isValid(itemData.PremiereDate)
        airDate = CreateObject("roDateTime")
        airDate.FromISO8601String(itemData.PremiereDate)
        m.top.findNode("aired").text = tr("Aired") + ": " + airDate.AsDateString("short-month-no-weekday")
    end if

    imageUrl = item.posterURL

    if get_user_setting("ui.tvshows.blurunwatched") = "true"
        if itemData.lookup("Type") = "Episode"
            if not itemData.userdata.played
                imageUrl = imageUrl + "&blur=15"
            end if
        end if
    end if

    m.poster.uri = imageUrl

    if type(itemData.RunTimeTicks) = "roInt" or type(itemData.RunTimeTicks) = "LongInteger"
        runTime = getRuntime()
        if runTime < 2
            m.top.findNode("runtime").text = "1 min"
        else
            m.top.findNode("runtime").text = stri(runTime).trim() + " mins"
        end if

        if get_user_setting("ui.design.hideclock") <> "true"
            m.top.findNode("endtime").text = tr("Ends at %1").Replace("%1", getEndTime())
        end if
    end if

    if get_user_setting("ui.tvshows.disableCommunityRating") = "false"
        if isValid(itemData.communityRating)
            m.top.findNode("star").visible = true
            m.top.findNode("communityRating").text = str(int(itemData.communityRating * 10) / 10)
        else
            m.top.findNode("star").visible = false
        end if
    else
        m.rating.visible = false
        m.infoBar.itemSpacings = [20, -25, 20, 20]
    end if

    ' Add checkmark in corner (if applicable)
    if isValid(itemData.UserData) and isValid(itemData.UserData.Played) and itemData.UserData.Played = true
        m.playedIndicator.visible = true
    end if

    ' Add progress bar on bottom (if applicable)
    if isValid(itemData.UserData) and isValid(itemData.UserData.PlayedPercentage) and itemData.UserData.PlayedPercentage > 0
        m.progressBackground.width = m.poster.width
        m.progressBackground.visible = true
        progressWidthInPixels = int(m.progressBackground.width * itemData.UserData.PlayedPercentage / 100)
        m.progressBar.width = progressWidthInPixels
        m.progressBar.visible = true
    end if

    videoIdx = invalid
    audioIdx = invalid

    if isValid(itemData.MediaStreams)
        for i = 0 to itemData.MediaStreams.Count() - 1
            if itemData.MediaStreams[i].Type = "Video" and videoIdx = invalid
                videoIdx = i
                m.top.findNode("video_codec").text = tr("Video") + ": " + itemData.mediaStreams[videoIdx].DisplayTitle
            else if itemData.MediaStreams[i].Type = "Audio" and audioIdx = invalid
                if item.selectedAudioStreamIndex > 1
                    audioIdx = item.selectedAudioStreamIndex
                else
                    audioIdx = i
                end if
                m.top.findNode("audio_codec").text = tr("Audio") + ": " + itemData.mediaStreams[audioIdx].DisplayTitle
            end if
            if isValid(videoIdx) and isValid(audioIdx) then exit for
        end for
    end if

    m.top.findNode("video_codec").visible = isValid(videoIdx)
    if isValid(audioIdx)
        m.top.findNode("audio_codec").visible = true
        DisplayAudioAvailable(itemData.mediaStreams)
    else
        m.top.findNode("audio_codec").visible = false
    end if
end sub

sub DisplayAudioAvailable(streams)
    count = 0
    for i = 0 to streams.Count() - 1
        if streams[i].Type = "Audio"
            count++
        end if
    end for

    if count > 1
        m.top.findnode("audio_codec_count").text = "+" + stri(count - 1).trim()
    end if
end sub

function getRuntime() as integer
    itemData = m.top.itemContent.json

    ' A tick is .1ms, so 1/10,000,000 for ticks to seconds,
    ' then 1/60 for seconds to minutess... 1/600,000,000
    return int(itemData.RunTimeTicks / 600000000.0)
end function

function getEndTime() as string
    itemData = m.top.itemContent.json
    date = CreateObject("roDateTime")
    duration_s = int(itemData.RunTimeTicks / 10000000.0)
    date.fromSeconds(date.asSeconds() + duration_s)
    date.toLocalTime()

    return formatTime(date)
end function

sub focusChanged()
    if m.top.itemHasFocus = true
        ' text to speech for accessibility
        if m.global.device.isAudioGuideEnabled = true
            txt2Speech = CreateObject("roTextToSpeech")
            txt2Speech.Flush()
            txt2Speech.Say(m.title.text)
            txt2Speech.Say(m.overview.text)
        end if
    end if
end sub
