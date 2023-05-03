sub init()
    m.top.optionsAvailable = false
    setupMainNode()
    setupButtons()

    m.remoteButtonsActive = true

    m.albumHeader = m.top.findNode("albumHeader")
    m.albumHeader.text = tr("Albums")

    m.appearsOnHeader = m.top.findNode("appearsOnHeader")
    m.appearsOnHeader.text = tr("AppearsOn")

    m.appearsOn = m.top.findNode("appearsOn")
    m.appearsOn.observeField("escape", "onAppearsOnEscape")
    m.appearsOn.observeField("MusicArtistAlbumData", "onAppearsOnData")

    m.albums = m.top.findNode("albums")
    m.albums.observeField("escape", "onAlbumsEscape")
    m.albums.observeField("MusicArtistAlbumData", "onAlbumsData")

    m.pageLoadAnimation = m.top.findNode("pageLoad")
    m.pageLoadAnimation.control = "start"

    m.sectionNavigation = m.top.findNode("sectionNavigation")
    m.sectionNavigation.observeField("escape", "onSectionNavigationEscape")
    m.sectionNavigation.observeField("selected", "onSectionNavigationSelected")

    m.sectionScroller = m.top.findNode("sectionScroller")
    m.sectionScroller.observeField("displayedIndex", "onSectionScrollerChange")
    m.overhang = m.top.getScene().findNode("overhang")

    ' Load background image
    m.LoadBackdropImageTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadBackdropImageTask.itemsToLoad = "backdropImage"

    m.backDrop = m.top.findNode("backdrop")
    m.artistImage = m.top.findNode("artistImage")
    m.dscr = m.top.findNode("overview")
    m.dscr.observeField("isTextEllipsized", "onEllipsisChanged")
    createDialogPallete()
end sub

sub onAlbumsData()
    ' We have no album data
    if m.albums.MusicArtistAlbumData.TotalRecordCount = 0
        m.sectionScroller.removeChild(m.top.findNode("albumsSlide"))
        m.sectionNavigation.removeChild(m.top.findNode("albumsLink"))
        m.top.findNode("appearsOnSlide").callFunc("scrollUpToOnDeck")
    end if
end sub

sub onAppearsOnData()
    ' We have no appears on data
    if m.appearsOn.MusicArtistAlbumData.TotalRecordCount = 0
        m.sectionScroller.removeChild(m.top.findNode("appearsOnSlide"))
        m.sectionNavigation.removeChild(m.top.findNode("appearsOnLink"))
    end if
end sub

sub onSectionScrollerChange()
    m.overhang.isVisible = (m.sectionScroller.displayedIndex = 0)
end sub

sub OnScreenShown()
    m.sectionScroller.focus = true

    if m.sectionScroller.displayedIndex = 0
        m.previouslySelectedButtonIndex = m.top.selectedButtonIndex
        m.top.selectedButtonIndex = 0
        m.buttonGrp.setFocus(true)
    else
        m.overhang.opacity = "0"
        m.overhang.isVisible = false
        m.overhang.opacity = "1"
    end if
end sub

sub OnScreenHidden()
    if not m.overhang.isVisible
        m.overhang.disableMoveAnimation = true
        m.overhang.isVisible = true
        m.overhang.disableMoveAnimation = false
        m.overhang.opacity = "1"
    end if
end sub

sub onAlbumsEscape()
    if m.albums.escape = "up"
        m.sectionNavigation.selected = m.sectionScroller.displayedIndex - 1
    else if m.albums.escape = "left"
        m.sectionNavigation.setFocus(true)
    else if m.albums.escape = "down"
        if m.sectionScroller.displayedIndex + 1 < m.sectionNavigation.getChildCount()
            m.sectionNavigation.selected = m.sectionScroller.displayedIndex + 1
        end if
    end if
end sub

sub onAppearsOnEscape()
    if m.appearsOn.escape = "up"
        m.sectionNavigation.selected = m.sectionScroller.displayedIndex - 1
    else if m.appearsOn.escape = "left"
        m.sectionNavigation.setFocus(true)
    end if
end sub

' Setup playback buttons, default to Play button selected
sub setupButtons()
    m.buttonGrp = m.top.findNode("buttons")
    m.buttonCount = m.buttonGrp.getChildCount()

    m.playButton = m.top.findNode("play")
    m.previouslySelectedButtonIndex = -1

    m.top.observeField("selectedButtonIndex", "onButtonSelectedChange")
    m.top.selectedButtonIndex = 0
end sub

' Event handler when user selected a different playback button
sub onButtonSelectedChange()
    ' Change previously selected button back to default image
    if m.previouslySelectedButtonIndex > -1
        previousSelectedButton = m.buttonGrp.getChild(m.previouslySelectedButtonIndex)
        previousSelectedButton.focus = false
    end if

    ' Change selected button image to selected image
    selectedButton = m.buttonGrp.getChild(m.top.selectedButtonIndex)
    selectedButton.focus = true
end sub

sub setupMainNode()
    m.main = m.top.findNode("toplevel")
    m.main.translation = [120, 175]
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
end sub

sub setScreenTitle(json)
    if isValid(json)
        m.top.overhangTitle = json.name
    end if
end sub

sub setPosterImage(posterURL)
    if not isValid(posterURL) or posterURL = ""
        posterURL = "pkg:/images/missingArtist.png"
    end if

    m.artistImage.uri = posterURL
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

' Event fired when page data is loaded
sub artistOverviewChanged()
    overviewContent = m.top.artistOverview

    if isValid(overviewContent)
        setFieldTextValue("overview", overviewContent)
    end if
end sub

sub onEllipsisChanged()
    if m.dscr.isTextEllipsized
        dscrShowFocus()
    end if
end sub

sub onSectionNavigationEscape()
    if m.sectionNavigation.escape = "right"
        m.sectionNavigation.setFocus(false)
        m.remoteButtonsActive = false
        m.sectionScroller.focus = true
    end if
end sub

sub onSectionNavigationSelected()
    m.sectionScroller.displayedIndex = m.sectionNavigation.selected
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

    if m.buttonGrp.isInFocusChain()
        if key = "OK"
            if press
                selectedButton = m.buttonGrp.getChild(m.top.selectedButtonIndex)
                selectedButton.selected = not selectedButton.selected
                return true
            end if
        end if

        if key = "left"
            if m.top.selectedButtonIndex > 0
                m.previouslySelectedButtonIndex = m.top.selectedButtonIndex
                m.top.selectedButtonIndex = m.top.selectedButtonIndex - 1
                return true
            end if

            if press
                selectedButton = m.buttonGrp.getChild(m.top.selectedButtonIndex)
                selectedButton.focus = false

                m.sectionNavigation.setFocus(true)
                return true
            end if

            return false
        end if

        if key = "right"
            if m.top.pageContent.count() = 1 then return false

            if m.buttonGrp.getChild(m.top.selectedButtonIndex).escape = "right"
                m.buttonGrp.getChild(m.top.selectedButtonIndex).escape = ""
                m.previouslySelectedButtonIndex = m.top.selectedButtonIndex

                if m.top.selectedButtonIndex < m.buttonCount - 1
                    m.top.selectedButtonIndex = m.top.selectedButtonIndex + 1
                end if

                return true
            end if
        end if

        if key = "down"
            if m.sectionNavigation.getChildCount() > 1
                selectedButton = m.buttonGrp.getChild(m.top.selectedButtonIndex)
                selectedButton.focus = false

                m.top.selectedButtonIndex = 0
                m.sectionNavigation.selected = m.sectionScroller.displayedIndex + 1
            end if
        end if
    end if

    if not press then return false

    if key = "options"
        if m.dscr.isTextEllipsized
            createFullDscrDlg()
            return true
        end if
    end if

    return false
end function
