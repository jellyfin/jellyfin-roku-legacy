sub init()
    m.top.optionsAvailable = false

    m.rows = m.top.findNode("picker")
    m.poster = m.top.findNode("seasonPoster")
    m.Random = m.top.findNode("Random")
    m.tvEpisodeRow = m.top.findNode("tvEpisodeRow")

    m.unplayedCount = m.top.findNode("unplayedCount")
    m.unplayedEpisodeCount = m.top.findNode("unplayedEpisodeCount")

    m.rows.observeField("doneLoading", "updateSeason")
end sub

sub setSeasonLoading()
    m.top.overhangTitle = tr("Loading...")
end sub

sub updateSeason()
    if get_user_setting("ui.tvshows.disableUnwatchedEpisodeCount", "false") = "false"
        if m.top.seasonData?.UserData?.UnplayedItemCount <> invalid
            if m.top.seasonData.UserData.UnplayedItemCount > 0
                m.unplayedCount.visible = true
                m.unplayedEpisodeCount.text = m.top.seasonData.UserData.UnplayedItemCount
            end if
        end if
    end if

    imgParams = { "maxHeight": 450, "maxWidth": 300 }
    m.poster.uri = ImageURL(m.top.seasonData.Id, "Primary", imgParams)
    m.Random.visible = true
    m.top.overhangTitle = m.top.seasonData.SeriesName + " - " + m.top.seasonData.name
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    handled = false

    if key = "left" and not m.Random.hasFocus()
        m.Random.setFocus(true)
        return true
    end if

    if key = "right" and not m.tvEpisodeRow.hasFocus()
        m.tvEpisodeRow.setFocus(true)
        return true
    end if


    if key = "OK" or key = "play"
        if m.Random.hasFocus()
            randomEpisode = Rnd(m.rows.getChild(0).objects.items.count()) - 1
            m.top.quickPlayNode = m.rows.getChild(0).objects.items[randomEpisode]
            return true
        end if
    end if


    focusedChild = m.top.focusedChild.focusedChild
    if focusedChild.content = invalid then return handled

    ' OK needs to be handled on release...
    proceed = false
    if key = "OK"
        proceed = true
    end if

    if press and key = "play" or proceed = true
        m.top.lastFocus = focusedChild
        itemToPlay = focusedChild.content.getChild(focusedChild.rowItemFocused[0]).getChild(0)
        if itemToPlay <> invalid and itemToPlay.id <> ""
            itemToPlay.type = "Episode"
            m.top.quickPlayNode = itemToPlay
        end if
        handled = true
    end if
    return handled
end function
