sub init()
    m.title = m.top.findNode("title")
    m.title.text = tr("Loading...")
    m.overview = m.top.findNode("overview")

    m.deviceInfo = CreateObject("roDeviceInfo")
end sub

sub itemContentChanged()
    item = m.top.itemContent
    itemData = item.json
    if itemData.indexNumber <> invalid
        indexNumber = itemData.indexNumber.toStr() + ". "
    else
        indexNumber = ""
    end if
    m.title.text = indexNumber + item.title
    m.top.findNode("poster").uri = item.posterURL
    m.overview.text = item.overview

    if type(itemData.RunTimeTicks) = "LongInteger"
        m.top.findNode("runtime").text = stri(getRuntime()).trim() + " mins"
        m.top.findNode("endtime").text = tr("Ends at %1").Replace("%1", getEndTime())
    end if

    if itemData.communityRating <> invalid
        m.top.findNode("star").visible = true
        m.top.findNode("communityRating").text = str(int(itemData.communityRating * 10) / 10)
    else
        m.top.findNode("star").visible = false
    end if

    videoIdx = invalid
    audioIdx = invalid
    if itemData.MediaStreams <> invalid
        for i = 0 to itemData.MediaStreams.Count() - 1
            if itemData.MediaStreams[i].Type = "Video" and videoIdx = invalid
                videoIdx = i
                m.top.findNode("video_codec").text = tr("Video") + ": " + itemData.mediaStreams[i].DisplayTitle
            else if itemData.MediaStreams[i].Type = "Audio" and audioIdx = invalid
                audioIdx = i
                m.top.findNode("audio_codec").text = tr("Audio") + ": " + itemData.mediaStreams[i].DisplayTitle
            end if
            if videoIdx <> invalid and audioIdx <> invalid then exit for
        end for
    end if
    m.top.findNode("video_codec").visible = videoIdx <> invalid
    m.top.findNode("audio_codec").visible = audioIdx <> invalid

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
        if m.deviceInfo.IsAudioGuideEnabled() = true
            txt2Speech = CreateObject("roTextToSpeech")
            txt2Speech.Flush()
            txt2Speech.Say(m.title.text)
            txt2Speech.Say(m.overview.text)
        end if
    end if
end sub
