sub init()
    m.dscr = m.top.findNode("description")
    m.vidsList = m.top.findNode("extrasGrid")
    m.btnGrp = m.top.findNode("buttons")
    m.btnGrp.observeField("escape", "onButtonGroupEscaped")
    m.favBtn = m.top.findNode("favorite-button")
    m.extrasGrp = m.top.findNode("extrasGrp")
    m.top.findNode("VertSlider").keyValue = "[[30, 998], [30, 789], [30, 580], [30,371 ], [30, 162]]"
    m.extrasGrp.opacity = 1.0
    m.extrasGrp.translation = "[30, 998]"
    m.dscr.observeField("isTextEllipsized", "onEllipsisChanged")
    createDialogPallete()
    m.top.optionsAvailable = false
end sub

sub loadPerson()
    item = m.top.itemContent
    itemData = item.json
    m.top.Id = itemData.id
    m.top.findNode("Name").Text = itemData.Name
    if itemData.PremiereDate <> invalid and itemData.PremiereDate <> ""
        birthDate = CreateObject("roDateTime")
        birthDate.FromISO8601String(itemData.PremiereDate)
        deathDate = CreateObject("roDatetime")
        lifeString = tr("Born") + ": " + birthDate.AsDateString("short-month-no-weekday")

        if itemData.EndDate <> invalid and itemData.EndDate <> ""
            deathDate.FromISO8601String(itemData.EndDate)
            lifeString = lifeString + " * " + tr("Died") + ": " + deathDate.AsDateString("short-month-no-weekday")

        end if
        ' Calculate age
        age = deathDate.getYear() - birthDate.getYear()
        if deathDate.getMonth() < birthDate.getMonth()
            age--
        else if deathDate.getMonth() = birthDate.getMonth()
            if deathDate.getDayOfMonth() < birthDate.getDayOfMonth()
                age--
            end if
        end if
        lifeString = lifeString + " * " + tr("Age") + ": " + stri(age)
        m.top.findNode("premierDate").Text = lifeString
    end if
    m.dscr.text = itemData.Overview
    if item.posterURL <> invalid and item.posterURL <> ""
        m.top.findnode("personImage").uri = item.posterURL
    else
        m.top.findnode("personImage").uri = "pkg:/images/baseline_person_white_48dp.png"
    end if
    m.vidsList.callFunc("loadPersonVideos", m.top.Id)

    setFavoriteColor()
    m.favBtn.setFocus(true)
end sub

sub onEllipsisChanged()
    if m.dscr.isTextEllipsized
        dscrShowFocus()
    end if
end sub

sub dscrShowFocus()
    if m.dscr.isTextEllipsized
        m.dscr.setFocus(true)
        m.dscr.opacity = 1.0
        m.top.findNode("dscrBorder").color = "#d0d0d0ff"
    end if
end sub

sub onButtonGroupEscaped()
    key = m.btnGrp.escape
    if key = "down"
        m.vidsList.setFocus(true)
        m.top.findNode("VertSlider").reverse = false
        m.top.findNode("pplAnime").control = "start"
    else if key = "up" and m.dscr.isTextEllipsized
        dscrShowFocus()
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "OK"
        if m.dscr.hasFocus() and m.dscr.isTextEllipsized
            createFullDscrDlg()
            return true
        end if
        return false
    end if

    if key = "back"
        m.global.sceneManager.callfunc("popScene")
        return true
    end if

    if key = "down"
        if m.dscr.hasFocus()
            m.favBtn.setFocus(true)
            m.dscr.opacity = 0.6
            m.top.findNode("dscrBorder").color = "#data202020ff"
            return true
        end if
    else if key = "up"
        if m.vidsList.isInFocusChain() and m.vidsList.itemFocused = 0
            m.top.findNode("VertSlider").reverse = true
            m.top.findNode("pplAnime").control = "start"
            m.favBtn.setFocus(true)
            return true
        end if
    end if
    return false
end function

sub setFavoriteColor()
    fave = m.top.itemContent.favorite
    fave_button = m.top.findNode("favorite-button")
    if fave <> invalid and fave
        fave_button.textColor = "#00ff00ff"
        fave_button.focusedTextColor = "#269926ff"
        fave_button.text = tr("Favorite")
    else
        fave_button.textColor = "0xddddddff"
        fave_button.focusedTextColor = "#262626ff"
        fave_button.text = tr("Set Favorite")
    end if
end sub

sub createFullDscrDlg()
    dlg = CreateObject("roSGNode", "OverviewDialog")
    dlg.Title = tr("Press 'OK' to Close")
    dlg.width = 1290
    dlg.palette = m.dlgPalette
    dlg.overview = [m.dscr.text]
    m.fullDscrDlg = dlg
    m.top.getScene().dialog = dlg
    border = createObject("roSGNode", "Poster")
    border.uri = "pkg:/images/hd_focul_9.png"
    border.blendColor = "#c9c9c9ff"
    border.width = dlg.width + 6
    border.height = dlg.height + 6
    border.translation = [dlg.translation[0] - 3, dlg.translation[1] - 3]
    border.visible = true
end sub

sub createDialogPallete()
    m.dlgPalette = createObject("roSGNode", "RSGPalette")
    m.dlgPalette.colors = {
        DialogBackgroundColor: "0x262828FF",
        DialogItemColor: "0x00EF00FF",
        DialogTextColor: "0xb0b0b0FF",
        DialogFocusColor: "0xcececeFF",
        DialogFocusItemColor: "0x202020FF",
        DialogSecondaryTextColor: "0xf8f8f8ff",
        DialogSecondaryItemColor: "0xcc7ecc4D",
        DialogInputFieldColor: "0x80FF8080",
        DialogKeyboardColor: "0x80FF804D",
        DialogFootprintColor: "0x80FF804D"
    }
end sub

function shortDate(isoDate) as string
    myDate = CreateObject("roDateTime")
    myDate.FromISO8601String(isoDate)
    return myDate.AsDateString("short-month-no-weekday")
end function
