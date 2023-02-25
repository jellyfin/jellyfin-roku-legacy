sub init()
    m.dscr = m.top.findNode("description")
    m.vidsList = m.top.findNode("extrasGrid")
    m.btnGrp = m.top.findNode("buttons")
    m.btnGrp.observeField("escape", "onButtonGroupEscaped")
    m.favBtn = m.top.findNode("favorite-button")
    m.extrasGrp = m.top.findNode("extrasGrp")
    m.extrasGrp.opacity = 1.0
    createDialogPallete()
    m.top.optionsAvailable = false
end sub

sub loadPerson()
    item = m.top.itemContent
    itemData = item.json
    m.top.Id = itemData.id
    name = m.top.findNode("Name")
    name.Text = itemData.Name
    name.font.size = 70
    if itemData.PremiereDate <> invalid and itemData.PremiereDate <> ""
        lifeStringLabel = createObject("rosgnode", "Label")
        lifeStringLabel.id = "premierDate"
        lifeStringLabel.font = "font:SmallestBoldSystemFont"
        lifeStringLabel.height = "100"
        lifeStringLabel.vertAlign = "bottom"
        name.vertAlign = "top"
        name.font.size = 60
        m.top.findNode("title_rectangle").appendChild(lifeStringLabel)
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
        lifeStringLabel.Text = lifeString
    end if
    if itemData.Overview <> invalid and itemData.Overview <> ""
        m.dscr.text = itemData.Overview
    else
        m.dscr.text = tr("Biographical information for this person is not currently available.")
        m.dscr.horizAlign = "center"
        m.dscr.vertAlign = "center"
    end if
    if item.posterURL <> invalid and item.posterURL <> ""
        m.top.findnode("personImage").uri = item.posterURL
    else
        m.top.findnode("personImage").uri = "pkg:/images/baseline_person_white_48dp.png"
    end if
    m.vidsList.callFunc("loadPersonVideos", m.top.Id)

    setFavoriteColor()
    if not m.favBtn.hasFocus() then dscrShowFocus()
end sub

sub dscrShowFocus()
    m.dscr.setFocus(true)
    m.dscr.opacity = 1.0
    m.top.findNode("dscrBorder").color = "#d0d0d0ff"
end sub

sub onButtonGroupEscaped()
    key = m.btnGrp.escape
    if key = "down"
        m.dscr.setFocus(true)
        m.dscr.opacity = 1.0
        m.top.findNode("dscrBorder").color = "#d0d0d0ff"
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "OK"
        if m.dscr.hasFocus()
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
            m.dscr.opacity = 0.6
            m.top.findNode("dscrBorder").color = "#data202020ff"
            m.vidsList.setFocus(true)
            m.top.findNode("VertSlider").reverse = false
            m.top.findNode("pplAnime").control = "start"
            return true
        end if
    else if key = "up"
        if m.dscr.hasFocus()
            m.favBtn.setFocus(true)
            m.dscr.opacity = 0.6
            m.top.findNode("dscrBorder").color = "#data202020ff"
            return true
        else if m.vidsList.isInFocusChain() and m.vidsList.itemFocused = 0
            m.top.findNode("VertSlider").reverse = true
            m.top.findNode("pplAnime").control = "start"
            dscrShowFocus()
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
    dlg.Title = m.top.itemContent.json.Name
    dlg.width = 1290
    dlg.palette = m.dlgPalette
    dlg.overview = m.dscr.text
    m.fullDscrDlg = dlg
    m.top.getScene().dialog = dlg

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
        KeyboardDialogColor: "0x80FF804D",
        DialogFootprintColor: "0x80FF804D"
    }
end sub

function shortDate(isoDate) as string
    myDate = CreateObject("roDateTime")
    myDate.FromISO8601String(isoDate)
    return myDate.AsDateString("short-month-no-weekday")
end function
