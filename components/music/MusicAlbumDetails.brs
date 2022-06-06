sub init()
    m.top.optionsAvailable = false
    setupMainNode()

    m.playAlbum = m.top.findNode("playAlbum")
    m.albumCover = m.top.findNode("albumCover")
    m.songList = m.top.findNode("songList")
    m.infoGroup = m.top.FindNode("infoGroup")
    m.songListRect = m.top.FindNode("songListRect")

    m.spinner = m.top.findNode("spinner")
    m.spinner.visible = true

    m.dscr = m.top.findNode("overview")
    m.dscr.observeField("isTextEllipsized", "onEllipsisChanged")
    createDialogPallete()
end sub

sub setupMainNode()
    main = m.top.findNode("toplevel")
    main.translation = [96, 175]
end sub

' Set values for displayed values on screen
sub pageContentChanged()
    item = m.top.pageContent
    m.spinner.visible = false

    setPosterImage(item.posterURL)
    setScreenTitle(item.json)
    setOnScreenTextValues(item.json)

    ' Only 1 song shown, so hide Play Album button
    if item.json.ChildCount = 1
        m.playAlbum.visible = false
    end if
end sub

' Set poster image on screen
sub setPosterImage(posterURL)
    if isValid(posterURL)
        m.albumCover.uri = posterURL
    end if
end sub

' Set screen's title text
sub setScreenTitle(json)
    newTitle = ""
    if isValid(json)
        if isValid(json.AlbumArtist)
            newTitle = json.AlbumArtist
        end if
        if isValid(json.AlbumArtist) and isValid(json.name)
            newTitle = newTitle + " / "
        end if
        if isValid(json.name)
            newTitle = newTitle + json.name
        end if
    end if
    m.top.overhangTitle = newTitle
end sub

' Adjust scene by removing overview node and showing more songs
sub adjustScreenForNoOverview()
    m.infoGroup.removeChild(m.dscr)
    m.songListRect.height = 800
    m.songList.numRows = 12
end sub

' Populate on screen text variables
sub setOnScreenTextValues(json)
    if isValid(json)
        if isValid(json.overview)
            ' Have have overview text
            setFieldTextValue("overview", json.overview)
        else
            ' We don't have overview text
            adjustScreenForNoOverview()
        end if

        setFieldTextValue("numberofsongs", stri(json.ChildCount) + " Tracks")

        if type(json.ProductionYear) = "roInt"
            setFieldTextValue("released", "Released " + stri(json.ProductionYear))
        end if

        if json.genres.count() > 0
            setFieldTextValue("genres", json.genres.join(", "))
        end if

        if type(json.RunTimeTicks) = "LongInteger"
            setFieldTextValue("runtime", stri(getMinutes(json.RunTimeTicks)) + " mins")
        end if
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if m.spinner.visible then return false

    ' Play Album is hidden, so there are no navigation needs here
    if m.top.pageContent.json.ChildCount = 1
        return false
    end if

    if key = "options"
        if m.dscr.isTextEllipsized
            createFullDscrDlg()
            return true
        end if
        return false
    end if

    if key = "right" and m.playAlbum.hasFocus()
        m.songList.setFocus(true)
        return true
    else if key = "left" and m.songList.hasFocus()
        m.playAlbum.setFocus(true)
        return true
    end if

    return false
end function

sub onEllipsisChanged()
    if m.dscr.isTextEllipsized
        dscrShowFocus()
    end if
end sub

sub dscrShowFocus()
    if m.dscr.isTextEllipsized
        m.dscr.setFocus(true)
        m.dscr.opacity = 1.0
    end if
end sub

sub createFullDscrDlg()
    dlg = CreateObject("roSGNode", "OverviewDialog")
    dlg.Title = tr("Press 'Back' to Close")
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

sub OnScreenHidden()
    m.spinner.visible = false
end sub
