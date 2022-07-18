sub init()
    m.top.optionsAvailable = false
    setupMainNode()

    ' Load background image
    m.LoadBackdropImageTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadBackdropImageTask.itemsToLoad = "backdropImage"

    m.backDrop = m.top.findNode("backdrop")
    m.artistImage = m.top.findNode("artistImage")
    m.dscr = m.top.findNode("overview")
    m.dscr.observeField("isTextEllipsized", "onEllipsisChanged")
    createDialogPallete()
end sub

sub setupMainNode()
    main = m.top.findNode("toplevel")
    main.translation = [96, 175]
end sub

' Event fired when page data is loaded
sub pageContentChanged()
    item = m.top.pageContent

    ' Use metadata to load backdrop image
    m.LoadBackdropImageTask.itemId = item.json.id
    m.LoadBackdropImageTask.observeField("content", "onBackdropImageLoaded")
    m.LoadBackdropImageTask.control = "RUN"

    ' Populate scene data
    setScreenTitle(item.json)
    setPosterImage(item.posterURL)
    setOnScreenTextValues(item.json)
end sub

sub setScreenTitle(json)
    if isValid(json)
        m.top.overhangTitle = json.name
    end if
end sub

sub setPosterImage(posterURL)
    if isValid(posterURL)
        m.artistImage.uri = posterURL
    end if
end sub

sub onBackdropImageLoaded()
    data = m.LoadBackdropImageTask.content[0]
    m.LoadBackdropImageTask.unobserveField("content")
    if isValid(data) and data <> ""
        setBackdropImage(data)
    end if
end sub

' Add backdrop image to screen
sub setBackdropImage(data)
    if isValid(data)
        if m.backDrop.uri <> data
            m.backDrop.uri = data
        end if
    end if
end sub

' Populate on screen text variables
sub setOnScreenTextValues(json)
    if isValid(json)
        setFieldTextValue("overview", json.overview)
    end if
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

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "options"
        if m.dscr.isTextEllipsized
            createFullDscrDlg()
            return true
        end if
    end if

    return false
end function
