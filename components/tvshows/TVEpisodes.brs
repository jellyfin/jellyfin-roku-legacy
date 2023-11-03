import "pkg:/source/api/Image.brs"
import "pkg:/source/api/baserequest.brs"
import "pkg:/source/utils/config.brs"
import "pkg:/source/utils/misc.brs"
import "pkg:/source/api/sdk.bs"

sub init()
    m.top.optionsAvailable = false

    m.rows = m.top.findNode("picker")
    m.poster = m.top.findNode("seasonPoster")
    m.shuffle = m.top.findNode("shuffle")
    m.extras = m.top.findNode("extras")
    m.tvEpisodeRow = m.top.findNode("tvEpisodeRow")

    m.unplayedCount = m.top.findNode("unplayedCount")
    m.unplayedEpisodeCount = m.top.findNode("unplayedEpisodeCount")

    m.rows.observeField("doneLoading", "updateSeason")
end sub

sub setSeasonLoading()
    m.top.overhangTitle = tr("Loading...")
end sub

' Updates the visibility of the Extras button based on if this season has any extra features
sub setExtraButtonVisibility()
    if isValid(m.top.extrasObjects) and isValidAndNotEmpty(m.top.extrasObjects.items)
        m.extras.visible = true
    end if
end sub

sub updateSeason()
    if m.global.session.user.settings["ui.tvshows.disableUnwatchedEpisodeCount"] = false
        if isValid(m.top.seasonData) and isValid(m.top.seasonData.UserData) and isValid(m.top.seasonData.UserData.UnplayedItemCount)
            if m.top.seasonData.UserData.UnplayedItemCount > 0
                m.unplayedCount.visible = true
                m.unplayedEpisodeCount.text = m.top.seasonData.UserData.UnplayedItemCount
            end if
        end if
    end if

    imgParams = { "maxHeight": 450, "maxWidth": 300 }
    m.poster.uri = ImageURL(m.top.seasonData.Id, "Primary", imgParams)
    m.shuffle.visible = true
    m.top.overhangTitle = m.top.seasonData.SeriesName + " - " + m.top.seasonData.name
end sub

' Handle navigation input from the remote and act on it
function onKeyEvent(key as string, press as boolean) as boolean
    handled = false

    if key = "left" and m.tvEpisodeRow.hasFocus()
        m.shuffle.setFocus(true)
        return true
    end if

    if key = "right" and (m.shuffle.hasFocus() or m.extras.hasFocus())
        m.tvEpisodeRow.setFocus(true)
        return true
    end if

    if m.extras.visible and key = "up" and m.extras.hasFocus()
        m.shuffle.setFocus(true)
        return true
    end if

    if m.extras.visible and key = "down" and m.shuffle.hasFocus()
        m.extras.setFocus(true)
        return true
    end if

    if key = "OK" or key = "play"
        if m.shuffle.hasFocus()
            episodeList = m.rows.getChild(0).objects.items

            for i = 0 to episodeList.count() - 1
                j = Rnd(episodeList.count() - 1)
                temp = episodeList[i]
                episodeList[i] = episodeList[j]
                episodeList[j] = temp
            end for

            m.global.queueManager.callFunc("set", episodeList)
            m.global.queueManager.callFunc("playQueue")
            return true
        end if

        if m.extras.visible and m.extras.hasFocus()
            if LCase(m.extras.text.trim()) = LCase(tr("Extras"))
                m.extras.text = tr("Episodes")
                m.top.objects = m.top.extrasObjects
            else
                m.extras.text = tr("Extras")
                m.top.objects = m.top.episodeObjects
            end if
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
        if isValid(itemToPlay) and isValid(itemToPlay.id) and itemToPlay.id <> ""
            m.top.quickPlayNode = itemToPlay
        end if
        handled = true
    end if
    return handled
end function
