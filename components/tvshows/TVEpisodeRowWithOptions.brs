sub init()
    m.rows = m.top.findNode("tvEpisodeRow")
    m.tvListOptions = m.top.findNode("tvListOptions")

    m.rows.observeField("doneLoading", "rowsDoneLoading")
end sub

sub setupRows()
    objects = m.top.objects
    m.rows.objects = objects
end sub

sub rowsDoneLoading()
    m.top.doneLoading = true
end sub

sub SetUpAudioOptions(streams)
    tracks = []

    for i = 0 to streams.Count() - 1
        if streams[i].Type = "Audio"
            tracks.push({ "Title": streams[i].displayTitle, "Description": streams[i].Title, "Selected": m.top.objects.items[m.currentSelected].selectedAudioStreamIndex = i, "StreamIndex": i })
        end if
    end for

    if tracks.count() > 1
        options = {}
        options.audios = tracks
        m.tvListOptions.options = options
        m.tvListOptions.visible = true
        m.tvListOptions.setFocus(true)
    end if
end sub

'
'Check if options updated and any reloading required
sub audioOptionsClosed()
    if m.currentSelected <> invalid
        ' If the user opened the audio options, we report back even if they left the selection alone.
        ' Otherwise, the users' lang peference from the server will take over.
        ' To do this, we interpret anything other than "0" as the user opened the audio options.
        m.top.objects.items[m.currentSelected].selectedAudioStreamIndex = m.tvListOptions.audioStreamIndex = 0 ? 1 : m.tvListOptions.audioStreamIndex
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "options" and m.rows.focusedChild <> invalid and m.rows.focusedChild.rowItemFocused <> invalid
        m.currentSelected = m.rows.focusedChild.rowItemFocused[0]
        mediaStreams = m.rows.objects.items[m.currentSelected].json.MediaStreams
        SetUpAudioOptions(mediaStreams)
        return true
    else if m.tvListOptions.visible = true and key = "back" or key = "options"
        m.tvListOptions.setFocus(false)
        m.tvListOptions.visible = false
        m.rows.setFocus(true)
        audioOptionsClosed()
        return true
    else if key = "up" and m.rows.hasFocus() = false
        m.rows.setFocus(true)
    else if key = "down" and m.rows.hasFocus() = false
        m.rows.setFocus(true)
    end if

    return false
end function
