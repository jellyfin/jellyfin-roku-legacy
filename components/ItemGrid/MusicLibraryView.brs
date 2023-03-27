sub setupNodes()
    m.options = m.top.findNode("options")
    m.itemGrid = m.top.findNode("itemGrid")
    m.voiceBox = m.top.findNode("voiceBox")
    m.backdrop = m.top.findNode("backdrop")
    m.newBackdrop = m.top.findNode("backdropTransition")
    m.emptyText = m.top.findNode("emptyText")
    m.selectedArtistName = m.top.findNode("selectedArtistName")
    m.selectedArtistSongCount = m.top.findNode("selectedArtistSongCount")
    m.selectedArtistAlbumCount = m.top.findNode("selectedArtistAlbumCount")
    m.selectedArtistGenres = m.top.findNode("selectedArtistGenres")
    m.artistLogo = m.top.findNode("artistLogo")
    m.swapAnimation = m.top.findNode("backroundSwapAnimation")
    m.spinner = m.top.findNode("spinner")
    m.Alpha = m.top.findNode("AlphaMenu")
    m.AlphaSelected = m.top.findNode("AlphaSelected")
    m.micButton = m.top.findNode("micButton")
    m.micButtonText = m.top.findNode("micButtonText")
    m.overhang = m.top.getScene().findNode("overhang")
    m.genreList = m.top.findNode("genrelist")
end sub

sub init()
    setupNodes()

    m.overhang.isVisible = false

    m.showItemCount = get_user_setting("itemgrid.showItemCount") = "true"

    m.swapAnimation.observeField("state", "swapDone")

    m.loadedRows = 0
    m.loadedItems = 0

    m.data = CreateObject("roSGNode", "ContentNode")

    m.itemGrid.content = m.data

    m.genreData = CreateObject("roSGNode", "ContentNode")
    m.genreList.observeField("itemSelected", "onGenreItemSelected")
    m.genreList.observeField("itemFocused", "onGenreItemFocused")
    m.genreList.content = m.genreData

    m.itemGrid.observeField("itemFocused", "onItemFocused")
    m.itemGrid.observeField("itemSelected", "onItemSelected")
    m.itemGrid.observeField("alphaSelected", "onItemalphaSelected")

    'Voice filter setup
    m.voiceBox.voiceEnabled = true
    m.voiceBox.active = true
    m.voiceBox.observeField("text", "onvoiceFilter")
    'set voice help text
    m.voiceBox.hintText = tr("Use voice remote to search")

    'backdrop
    m.newBackdrop.observeField("loadStatus", "newBGLoaded")

    'Background Image Queued for loading
    m.queuedBGUri = ""

    'Item sort - maybe load defaults from user prefs?
    m.sortField = "SortName"
    m.sortAscending = true

    m.filter = "All"
    m.favorite = "Favorite"

    m.loadItemsTask = createObject("roSGNode", "LoadItemsTask2")
    m.loadLogoTask = createObject("roSGNode", "LoadItemsTask2")

    'set inital counts for overhang before content is loaded.
    m.loadItemsTask.totalRecordCount = 0

    m.spinner.visible = true

    'Get reset folder setting
    m.resetGrid = get_user_setting("itemgrid.reset") = "true"

    'Hide voice search if device does not have voice remote
    if m.global.device.hasVoiceRemote = false
        m.micButton.visible = false
        m.micButtonText.visible = false
    end if
end sub

sub OnScreenHidden()
    if not m.overhang.isVisible
        m.overhang.disableMoveAnimation = true
        m.overhang.isVisible = true
        m.overhang.disableMoveAnimation = false
    end if
end sub

sub OnScreenShown()
    m.overhang.isVisible = false

    if m.top.lastFocus <> invalid
        m.top.lastFocus.setFocus(true)
    else
        m.top.setFocus(true)
    end if
end sub

'
'Load initial set of Data
sub loadInitialItems()
    m.loadItemsTask.control = "stop"
    m.spinner.visible = true

    if LCase(m.top.parentItem.json.Type) = "collectionfolder"
        m.top.HomeLibraryItem = m.top.parentItem.Id
    end if

    if m.top.parentItem.backdropUrl <> invalid
        SetBackground(m.top.parentItem.backdropUrl)
    else
        SetBackground("")
    end if

    m.sortField = get_user_setting("display." + m.top.parentItem.Id + ".sortField")
    sortAscendingStr = get_user_setting("display." + m.top.parentItem.Id + ".sortAscending")
    m.filter = get_user_setting("display." + m.top.parentItem.Id + ".filter")
    m.view = get_user_setting("display." + m.top.parentItem.Id + ".landing")

    if not isValid(m.sortField) then m.sortField = "SortName"
    if not isValid(m.filter) then m.filter = "All"
    if not isValid(m.view) then m.view = "ArtistsPresentation"

    if sortAscendingStr = invalid or LCase(sortAscendingStr) = "true"
        m.sortAscending = true
    else
        m.sortAscending = false
    end if

    m.top.showItemTitles = get_user_setting("itemgrid.gridTitles")

    if LCase(m.top.parentItem.json.type) = "musicgenre"
        m.itemGrid.translation = "[96, 60]"
        m.loadItemsTask.itemType = "MusicAlbum"
        m.loadItemsTask.recursive = true
        m.loadItemsTask.genreIds = m.top.parentItem.id
        m.loadItemsTask.itemId = m.top.parentItem.parentFolder
    else if LCase(m.view) = "artistspresentation" or LCase(m.options.view) = "artistspresentation"
        m.loadItemsTask.genreIds = ""
        m.top.showItemTitles = "hidealways"
    else if LCase(m.view) = "artistsgrid" or LCase(m.options.view) = "artistsgrid"
        m.loadItemsTask.genreIds = ""
    else
        m.loadItemsTask.itemId = m.top.parentItem.Id
    end if

    m.loadItemsTask.nameStartsWith = m.top.alphaSelected
    m.loadItemsTask.searchTerm = m.voiceBox.text
    m.emptyText.visible = false
    m.loadItemsTask.sortField = m.sortField
    m.loadItemsTask.sortAscending = m.sortAscending
    m.loadItemsTask.filter = m.filter
    m.loadItemsTask.startIndex = 0

    ' Load Item Types
    if getCollectionType() = "music"
        m.loadItemsTask.itemType = "MusicArtist"
        m.loadItemsTask.itemId = m.top.parentItem.Id
    end if

    ' By default we load Artists
    m.loadItemsTask.view = "Artists"
    m.itemGrid.translation = "[96, 420]"
    m.itemGrid.numRows = "3"

    if LCase(m.options.view) = "albums" or LCase(m.view) = "albums"
        m.itemGrid.translation = "[96, 60]"
        m.itemGrid.numRows = "4"
        m.loadItemsTask.itemType = "MusicAlbum"
        m.top.imageDisplayMode = "scaleToFit"
    else if LCase(m.options.view) = "artistsgrid" or LCase(m.view) = "artistsgrid"
        m.itemGrid.translation = "[96, 60]"
        m.itemGrid.numRows = "4"
    else if LCase(m.options.view) = "genres" or LCase(m.view) = "genres"
        m.loadItemsTask.itemType = ""
        m.loadItemsTask.recursive = true
        m.loadItemsTask.view = "Genres"
        m.artistLogo.visible = false
        m.selectedArtistName.visible = false
    end if

    if LCase(m.top.parentItem.json.type) = "musicgenre"
        m.itemGrid.translation = "[96, 60]"
        m.itemGrid.numRows = "4"
        m.artistLogo.visible = false
        m.selectedArtistName.visible = false
    end if

    m.loadItemsTask.observeField("content", "ItemDataLoaded")
    m.spinner.visible = true
    m.loadItemsTask.control = "RUN"
    SetUpOptions()
end sub

' Set Music view, sort, and filter options
sub setMusicOptions(options)

    options.views = [
        { "Title": tr("Artists (Presentation)"), "Name": "ArtistsPresentation" },
        { "Title": tr("Artists (Grid)"), "Name": "ArtistsGrid" },
        { "Title": tr("Albums"), "Name": "Albums" },
        { "Title": tr("Genres"), "Name": "Genres" }
    ]

    if LCase(m.top.parentItem.json.type) = "musicgenre"
        options.views = [
            { "Title": tr("Albums"), "Name": "Albums" }
        ]
    end if

    options.sort = [
        { "Title": tr("TITLE"), "Name": "SortName" },
        { "Title": tr("DATE_ADDED"), "Name": "DateCreated" },
        { "Title": tr("DATE_PLAYED"), "Name": "DatePlayed" },
        { "Title": tr("RELEASE_DATE"), "Name": "PremiereDate" },
    ]

    options.filter = [
        { "Title": tr("All"), "Name": "All" },
        { "Title": tr("Favorites"), "Name": "Favorites" }
    ]

    if LCase(m.options.view) = "genres" or LCase(m.view) = "genres"
        options.sort = [
            { "Title": tr("TITLE"), "Name": "SortName" },
        ]
        options.filter = []
    end if

    if LCase(m.options.view) = "albums" or LCase(m.view) = "albums"
        options.sort = [
            { "Title": tr("TITLE"), "Name": "SortName" },
            { "Title": tr("DATE_ADDED"), "Name": "DateCreated" },
        ]
    end if
end sub

' Return parent collection type
function getCollectionType() as string
    if m.top.parentItem.collectionType = invalid
        return LCase(m.top.parentItem.Type)
    else
        return LCase(m.top.parentItem.CollectionType)
    end if
end function

' Search string array for search value. Return if it's found
function inStringArray(array, searchValue) as boolean
    for each item in array
        if lcase(item) = lcase(searchValue) then return true
    end for
    return false
end function

' Data to display when options button selected
sub SetUpOptions()
    options = {}
    options.filter = []
    options.favorite = []

    setMusicOptions(options)

    ' Set selected view option
    for each o in options.views
        if LCase(o.Name) = LCase(m.view)
            o.Selected = true
            o.Ascending = m.sortAscending
            m.options.view = o.Name
        end if
    end for

    ' Set selected sort option
    for each o in options.sort
        if LCase(o.Name) = LCase(m.sortField)
            o.Selected = true
            o.Ascending = m.sortAscending
            m.options.sortField = o.Name
        end if
    end for

    ' Set selected filter option
    for each o in options.filter
        if LCase(o.Name) = LCase(m.filter)
            o.Selected = true
            m.options.filter = o.Name
        end if
    end for

    m.options.options = options
end sub

'
' Logo Image Loaded Event Handler
sub LogoImageLoaded(msg)
    data = msg.GetData()
    m.loadLogoTask.unobserveField("content")
    m.loadLogoTask.content = []

    if data.Count() > 0
        m.artistLogo.uri = data[0]
        m.artistLogo.visible = true
    else
        m.selectedArtistName.visible = true
    end if
end sub

'
'Handle loaded data, and add to Grid
sub ItemDataLoaded(msg)
    m.top.alphaActive = false
    itemData = msg.GetData()
    m.loadItemsTask.unobserveField("content")
    m.loadItemsTask.content = []

    if itemData = invalid
        m.Loading = false
        return
    end if

    if LCase(m.loadItemsTask.view) = "genres"
        for each item in itemData
            m.genreData.appendChild(item)
        end for

        m.itemGrid.opacity = "0"
        m.genreList.opacity = "1"

        m.itemGrid.setFocus(false)
        m.genreList.setFocus(true)

        m.loadedItems = m.genreList.content.getChildCount()
        m.loadedRows = m.loadedItems / m.genreList.numColumns

        m.loading = false
        m.spinner.visible = false
        return
    end if

    m.itemGrid.opacity = "1"
    m.genreList.opacity = "0"

    m.itemGrid.setFocus(true)
    m.genreList.setFocus(false)

    for each item in itemData
        m.data.appendChild(item)
    end for

    'Update the stored counts
    m.loadedItems = m.itemGrid.content.getChildCount()
    m.loadedRows = m.loadedItems / m.itemGrid.numColumns
    m.Loading = false
    'If there are no items to display, show message
    if m.loadedItems = 0
        m.emptyText.text = tr("NO_ITEMS").Replace("%1", m.top.parentItem.Type)
        m.emptyText.visible = true
    end if

    m.spinner.visible = false
end sub

'
'Set Selected Artist Name
sub SetName(artistName as string)
    m.selectedArtistName.text = artistName
end sub

'
'Set Selected Artist Song Count
sub SetSongCount(totalCount)
    appendText = " " + tr("Songs")
    if totalCount = 1
        appendText = " " + tr("Song")
    end if

    m.selectedArtistSongCount.text = totalCount.tostr() + appendText
end sub
'
'Set Selected Artist Album Count
sub SetAlbumCount(totalCount)
    appendText = " " + tr("Albums")
    if totalCount = 1
        appendText = " " + tr("Album")
    end if

    m.selectedArtistAlbumCount.text = totalCount.tostr() + appendText
end sub

'
'Set Selected Artist Genres
sub SetGenres(artistGenres)
    m.selectedArtistGenres.text = artistGenres.join(", ")
end sub

'
'Set Background Image
sub SetBackground(backgroundUri as string)
    if backgroundUri = ""
        m.backdrop.opacity = 0
    end if

    'If a new image is being loaded, or transitioned to, store URL to load next
    if LCase(m.swapAnimation.state) <> "stopped" or LCase(m.newBackdrop.loadStatus) = "loading"
        m.queuedBGUri = backgroundUri
        return
    end if

    m.newBackdrop.uri = backgroundUri
end sub

'
'Handle new item being focused
sub onItemFocused()
    focusedRow = m.itemGrid.currFocusRow

    itemInt = m.itemGrid.itemFocused

    ' If no selected item, set background to parent backdrop
    if itemInt = -1
        return
    end if

    m.artistLogo.visible = false
    m.selectedArtistName.visible = false
    m.selectedArtistGenres.visible = false
    m.selectedArtistSongCount.visible = false
    m.selectedArtistAlbumCount.visible = false

    ' Load more data if focus is within last 5 rows, and there are more items to load
    if focusedRow >= m.loadedRows - 5 and m.loadeditems < m.loadItemsTask.totalRecordCount
        loadMoreData()
    end if

    m.selectedFavoriteItem = getItemFocused()

    if LCase(m.options.view) = "albums" or LCase(m.view) = "albums" or LCase(m.top.parentItem.json.type) = "musicgenre"
        return
    end if

    if LCase(m.options.view) = "artistsgrid" or LCase(m.view) = "artistsgrid"
        return
    end if

    if not m.selectedArtistGenres.visible
        m.selectedArtistGenres.visible = true
    end if

    if not m.selectedArtistSongCount.visible
        m.selectedArtistSongCount.visible = true
    end if

    if not m.selectedArtistAlbumCount.visible
        m.selectedArtistAlbumCount.visible = true
    end if

    itemData = m.selectedFavoriteItem.json

    if isValid(itemData.SongCount)
        SetSongCount(itemData.SongCount)
    else
        SetSongCount("")
    end if

    if isValid(itemData.AlbumCount)
        SetAlbumCount(itemData.AlbumCount)
    else
        SetAlbumCount("")
    end if

    if isValid(itemData.Genres)
        SetGenres(itemData.Genres)
    else
        SetGenres([])
    end if

    if isValid(itemData.Name)
        SetName(itemData.Name)
    else
        SetName("")
    end if

    m.loadLogoTask.itemId = itemData.id
    m.loadLogoTask.itemType = "LogoImage"
    m.loadLogoTask.observeField("content", "LogoImageLoaded")
    m.loadLogoTask.control = "RUN"

    ' Set Background to item backdrop
    SetBackground(m.selectedFavoriteItem.backdropUrl)
end sub

sub setFieldText(field, value)
    node = m.top.findNode(field)
    if node = invalid or value = invalid then return

    ' Handle non strings... Which _shouldn't_ happen, but hey
    if type(value) = "roInt" or type(value) = "Integer"
        value = str(value)
    else if type(value) = "roFloat" or type(value) = "Float"
        value = str(value)
    else if type(value) <> "roString" and type(value) <> "String"
        value = ""
    end if

    node.text = value
end sub

'
'When Image Loading Status changes
sub newBGLoaded()
    'If image load was sucessful, start the fade swap
    if LCase(m.newBackdrop.loadStatus) = "ready"
        m.swapAnimation.control = "start"
    end if
end sub

'
'Swap Complete
sub swapDone()
    if LCase(m.swapAnimation.state) = "stopped"
        'Set main BG node image and hide transitioning node
        m.backdrop.uri = m.newBackdrop.uri
        m.backdrop.opacity = 1
        m.newBackdrop.opacity = 0

        'If there is another one to load
        if m.newBackdrop.uri <> m.queuedBGUri and m.queuedBGUri <> ""
            SetBackground(m.queuedBGUri)
            m.queuedBGUri = ""
        end if
    end if
end sub

'
'Load next set of items
sub loadMoreData()
    m.spinner.visible = true
    if m.Loading = true then return
    m.Loading = true
    m.loadItemsTask.startIndex = m.loadedItems
    m.loadItemsTask.observeField("content", "ItemDataLoaded")
    m.loadItemsTask.control = "RUN"
end sub

'
'Item Selected
sub onItemSelected()
    m.top.selectedItem = m.itemGrid.content.getChild(m.itemGrid.itemSelected)
end sub

'
'Returns Focused Item
function getItemFocused()
    return m.itemGrid.content.getChild(m.itemGrid.itemFocused)
end function

'
'Genre Item Selected
sub onGenreItemSelected()
    m.top.selectedItem = m.genreList.content.getChild(m.genreList.itemSelected)
end sub

'
'Genre Item Focused
sub onGenreItemFocused()
    focusedRow = m.genreList.currFocusRow

    ' Load more data if focus is within last 5 rows, and there are more items to load
    if focusedRow >= m.loadedRows - 5 and m.loadeditems < m.loadItemsTask.totalRecordCount
        loadMoreData()
    end if
end sub

sub onItemalphaSelected()
    if m.top.alphaSelected <> ""
        m.loadedRows = 0
        m.loadedItems = 0

        m.data = CreateObject("roSGNode", "ContentNode")
        m.itemGrid.content = m.data

        m.genreData = CreateObject("roSGNode", "ContentNode")
        m.genreList.content = m.genreData

        m.loadItemsTask.searchTerm = ""
        m.VoiceBox.text = ""
        m.loadItemsTask.nameStartsWith = m.alpha.itemAlphaSelected
        m.spinner.visible = true
        loadInitialItems()
    end if
end sub

sub onvoiceFilter()
    if m.VoiceBox.text <> ""
        m.loadedRows = 0
        m.loadedItems = 0
        m.data = CreateObject("roSGNode", "ContentNode")
        m.itemGrid.content = m.data
        m.top.alphaSelected = ""
        m.loadItemsTask.NameStartsWith = " "
        m.loadItemsTask.searchTerm = m.voiceBox.text
        m.loadItemsTask.recursive = true
        m.spinner.visible = true
        loadInitialItems()
    end if
end sub


'
'Check if options updated and any reloading required
sub optionsClosed()
    reload = false

    if m.options.sortField <> m.sortField or m.options.sortAscending <> m.sortAscending
        m.sortField = m.options.sortField
        m.sortAscending = m.options.sortAscending
        reload = true

        sortAscendingStr = "true"

        'Store sort settings
        if not m.sortAscending
            sortAscendingStr = "false"
        end if

        set_user_setting("display." + m.top.parentItem.Id + ".sortField", m.sortField)
        set_user_setting("display." + m.top.parentItem.Id + ".sortAscending", sortAscendingStr)
    end if

    if m.options.filter <> m.filter
        m.filter = m.options.filter
        reload = true
        set_user_setting("display." + m.top.parentItem.Id + ".filter", m.options.filter)
    end if

    m.view = get_user_setting("display." + m.top.parentItem.Id + ".landing")

    if m.options.view <> m.view
        m.view = m.options.view
        m.top.view = m.view
        set_user_setting("display." + m.top.parentItem.Id + ".landing", m.view)

        ' Reset any filtering or search terms
        m.top.alphaSelected = ""
        m.loadItemsTask.NameStartsWith = " "
        m.loadItemsTask.searchTerm = ""
        m.filter = "All"
        m.sortField = "SortName"
        m.sortAscending = true

        ' Reset view to defaults
        set_user_setting("display." + m.top.parentItem.Id + ".sortField", m.sortField)
        set_user_setting("display." + m.top.parentItem.Id + ".sortAscending", "true")
        set_user_setting("display." + m.top.parentItem.Id + ".filter", m.filter)

        reload = true
    end if

    if reload
        m.loadedRows = 0
        m.loadedItems = 0
        m.data = CreateObject("roSGNode", "ContentNode")
        m.genreData = CreateObject("roSGNode", "ContentNode")
        m.itemGrid.content = m.data
        m.genreList.content = m.genreData
        loadInitialItems()
    end if

    m.itemGrid.setFocus(m.itemGrid.opacity = 1)
    m.genreList.setFocus(m.genreList.opacity = 1)
end sub

sub onChannelSelected(msg)
    node = msg.getRoSGNode()
    m.top.lastFocus = lastFocusedChild(node)
    if node.watchChannel <> invalid
        ' Clone the node when it's reused/update in the TimeGrid it doesn't automatically start playing
        m.top.selectedItem = node.watchChannel.clone(false)
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "left" and m.voiceBox.isinFocusChain()
        m.itemGrid.setFocus(m.itemGrid.opacity = 1)
        m.genreList.setFocus(m.genreList.opacity = 1)
        m.voiceBox.setFocus(false)
    end if

    if key = "options"
        if m.options.visible = true
            m.options.visible = false
            m.top.removeChild(m.options)
            optionsClosed()
        else

            itemSelected = m.selectedFavoriteItem
            if itemSelected <> invalid
                m.options.selectedFavoriteItem = itemSelected
            end if

            m.options.visible = true
            m.top.appendChild(m.options)
            m.options.setFocus(true)
        end if
        return true
    else if key = "back"
        if m.options.visible = true
            m.options.visible = false
            optionsClosed()
            return true
        else
            m.global.sceneManager.callfunc("popScene")
            m.loadItemsTask.control = "stop"
            return true
        end if
    else if key = "left"
        if m.itemGrid.isinFocusChain()
            m.top.alphaActive = true
            m.itemGrid.setFocus(false)
            alpha = m.alpha.getChild(0).findNode("Alphamenu")
            alpha.setFocus(true)
            return true
        else if m.genreList.isinFocusChain()
            m.top.alphaActive = true
            m.genreList.setFocus(false)
            alpha = m.alpha.getChild(0).findNode("Alphamenu")
            alpha.setFocus(true)
            return true
        end if

    else if key = "right" and m.Alpha.isinFocusChain()
        m.top.alphaActive = false
        m.Alpha.setFocus(false)
        m.Alpha.visible = true

        m.itemGrid.setFocus(m.itemGrid.opacity = 1)
        m.genreList.setFocus(m.genreList.opacity = 1)

        return true

    else if key = "replay" and m.itemGrid.isinFocusChain()
        if m.resetGrid = true
            m.itemGrid.animateToItem = 0
        else
            m.itemGrid.jumpToItem = 0
        end if

    else if key = "replay" and m.genreList.isinFocusChain()
        if m.resetGrid = true
            m.genreList.animateToItem = 0
        else
            m.genreList.jumpToItem = 0
        end if
        return true
    end if

    if key = "replay"
        m.spinner.visible = true
        m.loadItemsTask.searchTerm = ""
        m.loadItemsTask.nameStartsWith = ""
        m.voiceBox.text = ""
        m.top.alphaSelected = ""
        m.loadItemsTask.filter = "All"
        m.filter = "All"
        m.data = CreateObject("roSGNode", "ContentNode")
        m.itemGrid.content = m.data
        loadInitialItems()
        return true
    end if

    return false
end function
