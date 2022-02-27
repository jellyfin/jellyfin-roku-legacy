sub init()
    m.dscr = m.top.findNode("description")
    m.vidsList = m.top.findNode("extrasGrid")
    m.btnGrp = m.top.findNode("buttons")
    m.favBtn = m.top.findNode("favorite-button")
    createDialogPallete()
    'm.topGrp.translation = [24, 165]
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

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "OK"
        if m.dscr.hasFocus() and m.dscr.isTextEllipsized
            createFullDscrDlg()
            return true
            'else if m.dscr.hasFocus()
            '    m.top.getScene().dialog = m.fullDscrDlg
            '    return true
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
            m.dscr.color = "#bbbbbbff"
            return true
        else if m.favBtn.hasFocus()
            m.vidsList.setFocus(true)
            m.top.findNode("VertSlider").reverse = false
            m.top.findNode("extrasFader").reverse = false
            m.top.findNode("pplAnime").control = "start"
            return true
        end if
    else if key = "up"
        if m.favBtn.hasFocus()
            m.dscr.setFocus(true)
            m.dscr.color = "#ddfeddff"
            return true
        else if m.vidsList.isInFocusChain() and m.vidsList.itemFocused = 0
            m.top.findNode("VertSlider").reverse = true
            m.top.findNode("extrasFader").reverse = true
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
    else
        fave_button.textColor = "0xddddddff"
        fave_button.focusedTextColor = "#262626ff"
    end if
end sub

sub createFullDscrDlg()
    dlg = CreateObject("roSGNode", "StandardMessageDialog")
    dlg.width = 1620
    dlg.height = 750
    dlg.translation = [250, 180]
    dlg.palette = m.dlgPalette
    dlg.message = [m.dscr.text]
    dlg.buttons = [tr("Close")]
    dlg.observeFieldScoped("buttonSelected", "onButtonSelected")
    m.fullDscrDlg = dlg
    m.top.getScene().dialog = dlg
end sub

sub onButtonSelected()
    ' we have only one button
    m.fullDscrDlg.close = true
end sub

sub createDialogPallete()
    m.dlgPalette = createObject("roSGNode", "RSGPalette")
    m.dlgPalette.colors = {
        DialogBackgroundColor: "0x101010FF",
        DialogItemColor: "0x00EF00FF",
        DialogTextColor: "0xccEFccFF",
        DialogFocusColor: "0x008e00FF",
        DialogFocusItemColor: "0xdeeedeFF",
        DialogSecondaryTextColor: "0xcc7ecc66",
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
