sub init()

    m.options = m.top.findNode("options")

    m.showItemCount = get_user_setting("itemgrid.showItemCount") = "true"

    m.tvGuide = invalid
    m.channelFocused = invalid

    m.itemGrid = m.top.findNode("itemGrid")
    m.backdrop = m.top.findNode("backdrop")
    m.newBackdrop = m.top.findNode("backdropTransition")
    m.emptyText = m.top.findNode("emptyText")

    m.swapAnimation = m.top.findNode("backroundSwapAnimation")
    m.swapAnimation.observeField("state", "swapDone")

    m.loadedRows = 0
    m.loadedItems = 0

    m.data = CreateObject("roSGNode", "ContentNode")

    m.itemGrid.content = m.data
    m.itemGrid.setFocus(true)

    m.itemGrid.observeField("itemFocused", "onItemFocused")
    m.itemGrid.observeField("itemSelected", "onItemSelected")
    m.itemGrid.observeField("alphaSelected", "onItemalphaSelected")

    'Voice filter setup
    m.voiceBox = m.top.findNode("voiceBox")
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

    'set inital counts for overhang before content is loaded.
    m.loadItemsTask.totalRecordCount = 0

    m.spinner = m.top.findNode("spinner")
    m.spinner.visible = true

    m.Alpha = m.top.findNode("AlphaMenu")
    m.AlphaSelected = m.top.findNode("AlphaSelected")

    'Get reset folder setting
    m.resetGrid = get_user_setting("itemgrid.reset") = "true"

    'Check if device has voice remote
    devinfo = CreateObject("roDeviceInfo")
    m.deviFeature = devinfo.HasFeature("voice_remote")
    m.micButton = m.top.findNode("micButton")
    m.micButtonText = m.top.findNode("micButtonText")
    'Hide voice search if device does not have voice remote
    if m.deviFeature = false
        m.micButton.visible = false
        m.micButtonText.visible = false
    end if
end sub

'
'Load initial set of Data
sub loadInitialItems()
    m.loadItemsTask.control = "stop"
    m.spinner.visible = true

    if m.top.parentItem.json.Type = "CollectionFolder" 'or m.top.parentItem.json.Type = "Folder"
        m.top.HomeLibraryItem = m.top.parentItem.Id
    end if

    if m.top.parentItem.backdropUrl <> invalid
        SetBackground(m.top.parentItem.backdropUrl)
    end if

    ' Read view/sort/filter settings
    if m.top.parentItem.collectionType = "livetv"
        ' Translate between app and server nomenclature
        viewSetting = get_user_setting("display.livetv.landing")
        'Move mic to be visiable on TV Guide screen
        if m.deviFeature = true
            m.micButton.translation = "[1540, 92]"
            m.micButtonText.visible = true
            m.micButtonText.translation = "[1600,130]"
            m.micButtonText.font.size = 22
            m.micButtonText.text = tr("Search")
        end if
        if viewSetting = "guide"
            m.view = "tvGuide"
        else
            m.view = "livetv"
        end if
        m.sortField = get_user_setting("display.livetv.sortField")
        sortAscendingStr = get_user_setting("display.livetv.sortAscending")
        m.filter = get_user_setting("display.livetv.filter")
    else if m.top.parentItem.collectionType = "music"
        m.view = get_user_setting("display.music.view")
        m.sortField = get_user_setting("display." + m.top.parentItem.Id + ".sortField")
        sortAscendingStr = get_user_setting("display." + m.top.parentItem.Id + ".sortAscending")
        m.filter = get_user_setting("display." + m.top.parentItem.Id + ".filter")
    else
        m.sortField = get_user_setting("display." + m.top.parentItem.Id + ".sortField")
        sortAscendingStr = get_user_setting("display." + m.top.parentItem.Id + ".sortAscending")
        m.filter = get_user_setting("display." + m.top.parentItem.Id + ".filter")
        m.view = get_user_setting("display." + m.top.parentItem.Id + ".landing")
    end if

    if m.sortField = invalid then m.sortField = "SortName"
    if m.filter = invalid then m.filter = "All"

    if sortAscendingStr = invalid or sortAscendingStr = "true"
        m.sortAscending = true
    else
        m.sortAscending = false
    end if
    ' Set Studio Id
    if m.top.parentItem.json.type = "Studio"
        m.loadItemsTask.studioIds = m.top.parentItem.id
        m.loadItemsTask.itemId = m.top.parentItem.parentFolder
        m.loadItemsTask.genreIds = ""
        ' Set Genre Id
    else if m.top.parentItem.json.type = "Genre"
        m.loadItemsTask.genreIds = m.top.parentItem.id
        m.loadItemsTask.itemId = m.top.parentItem.parentFolder
        m.loadItemsTask.studioIds = ""
    else if (m.view = "Shows" or m.options.view = "Shows") or (m.view = "Movies" or m.options.view = "Movies")
        m.loadItemsTask.studioIds = ""
        m.loadItemsTask.genreIds = ""
    else
        m.loadItemsTask.itemId = m.top.parentItem.Id
    end if
    updateTitle()

    m.loadItemsTask.nameStartsWith = m.top.alphaSelected
    m.loadItemsTask.searchTerm = m.voiceBox.text
    m.emptyText.visible = false
    m.loadItemsTask.sortField = m.sortField
    m.loadItemsTask.sortAscending = m.sortAscending
    m.loadItemsTask.filter = m.filter
    m.loadItemsTask.startIndex = 0

    ' Load Item Types
    if getCollectionType() = "movies"
        m.loadItemsTask.itemType = "Movie"
        m.loadItemsTask.itemId = m.top.parentItem.Id
    else if getCollectionType() = "tvshows"
        m.loadItemsTask.itemType = "Series"
        m.loadItemsTask.itemId = m.top.parentItem.Id
    else if getCollectionType() = "music"
        ' Default Settings
        m.loadItemsTask.recursive = true
        m.itemGrid.itemSize = "[290, 290]"

        m.loadItemsTask.itemType = "MusicArtist"
        m.loadItemsTask.itemId = m.top.parentItem.Id

        m.view = get_user_setting("display.music.view")

        if m.view = "music-album"
            m.loadItemsTask.itemType = "MusicAlbum"
        end if
    else if m.top.parentItem.collectionType = "livetv"
        m.loadItemsTask.itemType = "TvChannel"
        m.loadItemsTask.itemId = " "
        ' For LiveTV, we want to "Fit" the item images, not zoom
        m.top.imageDisplayMode = "scaleToFit"

        if get_user_setting("display.livetv.landing") = "guide" and m.options.view <> "livetv"
            showTvGuide()
        end if
    else if m.top.parentItem.collectionType = "CollectionFolder" or m.top.parentItem.type = "CollectionFolder" or m.top.parentItem.collectionType = "boxsets" or m.top.parentItem.Type = "Boxset" or m.top.parentItem.Type = "Boxsets" or m.top.parentItem.Type = "Folder" or m.top.parentItem.Type = "Channel"
        if m.voiceBox.text <> ""
            m.loadItemsTask.recursive = true
        else
            ' non recursive for collections (folders, boxsets, photo albums, etc)
            m.loadItemsTask.recursive = false
        end if
    else if m.top.parentItem.json.type = "Studio"
        m.loadItemsTask.itemId = m.top.parentItem.parentFolder
        m.loadItemsTask.itemType = "Series,Movie"
        m.top.imageDisplayMode = "scaleToFit"
    else if m.top.parentItem.json.type = "Genre"
        m.loadItemsTask.itemType = "Series,Movie"
        m.loadItemsTask.itemId = m.top.parentItem.parentFolder
    else
        print "[ItemGrid] Unknown Type: " m.top.parentItem
    end if

    if m.top.parentItem.type <> "Folder" and (m.options.view = "Networks" or m.view = "Networks" or m.options.view = "Studios" or m.view = "Studios")
        m.loadItemsTask.view = "Networks"
        m.top.imageDisplayMode = "scaleToFit"
    else if m.top.parentItem.type <> "Folder" and (m.options.view = "Genres" or m.view = "Genres")
        m.loadItemsTask.StudioIds = m.top.parentItem.Id
        m.loadItemsTask.view = "Genres"
    else if m.top.parentItem.type <> "Folder" and (m.options.view = "Shows" or m.view = "Shows")
        m.loadItemsTask.studioIds = ""
        m.loadItemsTask.view = "Shows"
    else if m.top.parentItem.type <> "Folder" and (m.options.view = "Movies" or m.view = "Movies")
        m.loadItemsTask.studioIds = ""
        m.loadItemsTask.view = "Movies"
    end if

    m.loadItemsTask.observeField("content", "ItemDataLoaded")
    m.spinner.visible = true
    m.loadItemsTask.control = "RUN"
    SetUpOptions()
end sub

' Set Movies view, sort, and filter options
sub setMoviesOptions(options)
    options.views = [
        { "Title": tr("Movies"), "Name": "Movies" },
        { "Title": tr("Studios"), "Name": "Studios" },
        { "Title": tr("Genres"), "Name": "Genres" }
    ]
    options.sort = [
        { "Title": tr("TITLE"), "Name": "SortName" },
        { "Title": tr("IMDB_RATING"), "Name": "CommunityRating" },
        { "Title": tr("CRITIC_RATING"), "Name": "CriticRating" },
        { "Title": tr("DATE_ADDED"), "Name": "DateCreated" },
        { "Title": tr("DATE_PLAYED"), "Name": "DatePlayed" },
        { "Title": tr("OFFICIAL_RATING"), "Name": "OfficialRating" },
        { "Title": tr("PLAY_COUNT"), "Name": "PlayCount" },
        { "Title": tr("RELEASE_DATE"), "Name": "PremiereDate" },
        { "Title": tr("RUNTIME"), "Name": "Runtime" }
    ]
    options.filter = [
        { "Title": tr("All"), "Name": "All" },
        { "Title": tr("Favorites"), "Name": "Favorites" }
    ]
end sub

' Set Boxset view, sort, and filter options
sub setBoxsetsOptions(options)
    options.views = [{ "Title": tr("Shows"), "Name": "shows" }]
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
end sub

' Set TV Show view, sort, and filter options
sub setTvShowsOptions(options)
    options.views = [
        { "Title": tr("Shows"), "Name": "Shows" },
        { "Title": tr("Networks"), "Name": "Networks" },
        { "Title": tr("Genres"), "Name": "Genres" }

    ]
    options.sort = [
        { "Title": tr("TITLE"), "Name": "SortName" },
        { "Title": tr("IMDB_RATING"), "Name": "CommunityRating" },
        { "Title": tr("DATE_ADDED"), "Name": "DateCreated" },
        { "Title": tr("DATE_PLAYED"), "Name": "DatePlayed" },
        { "Title": tr("OFFICIAL_RATING"), "Name": "OfficialRating" },
        { "Title": tr("RELEASE_DATE"), "Name": "PremiereDate" },
    ]
    options.filter = [
        { "Title": tr("All"), "Name": "All" },
        { "Title": tr("Favorites"), "Name": "Favorites" }
    ]
end sub

' Set Live TV view, sort, and filter options
sub setLiveTvOptions(options)
    options.views = [
        { "Title": tr("Channels"), "Name": "livetv" },
        { "Title": tr("TV Guide"), "Name": "tvGuide" }
    ]
    options.sort = [
        { "Title": tr("TITLE"), "Name": "SortName" }
    ]
    options.filter = [
        { "Title": tr("All"), "Name": "All" },
        { "Title": tr("Favorites"), "Name": "Favorites" }
    ]
    options.favorite = [
        { "Title": tr("Favorite"), "Name": "Favorite" }
    ]
end sub

' Set Music view, sort, and filter options
sub setMusicOptions(options)
    options.views = [
        { "Title": tr("Artists"), "Name": "music-artist" },
        { "Title": tr("Albums"), "Name": "music-album" },
    ]
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
end sub

' Set Photo Album view, sort, and filter options
sub setPhotoAlbumOptions(options)
    options.views = [
        { "Title": tr("Slideshow Off"), "Name": "singlephoto" }
        { "Title": tr("Slideshow On"), "Name": "slideshowphoto" }
        { "Title": tr("Random Off"), "Name": "singlephoto" }
        { "Title": tr("Random On"), "Name": "randomphoto" }
    ]
    options.sort = []
    options.filter = []
end sub

' Set Default view, sort, and filter options
sub setDefaultOptions(options)
    options.views = [
        { "Title": tr("Default"), "Name": "default" }
    ]
    options.sort = [
        { "Title": tr("TITLE"), "Name": "SortName" }
    ]
end sub

' Return parent collection type
function getCollectionType() as string
    if m.top.parentItem.collectionType = invalid
        return m.top.parentItem.Type
    else
        return m.top.parentItem.CollectionType
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

    if getCollectionType() = "movies"
        setMoviesOptions(options)
    else if inStringArray(["boxsets", "Boxset"], getCollectionType())
        setBoxsetsOptions(options)
    else if getCollectionType() = "tvshows"
        setTvShowsOptions(options)
    else if getCollectionType() = "livetv"
        setLiveTvOptions(options)
    else if inStringArray(["photoalbum", "photo", "homevideos"], getCollectionType())
        setPhotoAlbumOptions(options)
    else if getCollectionType() = "music"
        setMusicOptions(options)

    else
        setDefaultOptions(options)
    end if

    ' Set selected view option
    for each o in options.views
        if o.Name = m.view
            o.Selected = true
            o.Ascending = m.sortAscending
            m.options.view = o.Name
        end if
    end for

    ' Set selected sort option
    for each o in options.sort
        if o.Name = m.sortField
            o.Selected = true
            o.Ascending = m.sortAscending
            m.options.sortField = o.Name
        end if
    end for

    ' Set selected filter option
    for each o in options.filter
        if o.Name = m.filter
            o.Selected = true
            m.options.filter = o.Name
        end if
    end for

    m.options.options = options
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

    m.itemGrid.setFocus(true)
    m.spinner.visible = false
end sub

'
'Set Background Image
sub SetBackground(backgroundUri as string)

    'If a new image is being loaded, or transitioned to, store URL to load next
    if m.swapAnimation.state <> "stopped" or m.newBackdrop.loadStatus = "loading"
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

    updateTitle()

    ' If no selected item, set background to parent backdrop
    if itemInt = -1
        return
    end if

    m.selectedFavoriteItem = m.itemGrid.content.getChild(m.itemGrid.itemFocused)

    ' Set Background to item backdrop
    SetBackground(m.itemGrid.content.getChild(m.itemGrid.itemFocused).backdropUrl)

    ' Load more data if focus is within last 5 rows, and there are more items to load
    if focusedRow >= m.loadedRows - 5 and m.loadeditems < m.loadItemsTask.totalRecordCount
        loadMoreData()
    end if
end sub

'
'When Image Loading Status changes
sub newBGLoaded()
    'If image load was sucessful, start the fade swap
    if m.newBackdrop.loadStatus = "ready"
        m.swapAnimation.control = "start"
    end if
end sub

'
'Swap Complete
sub swapDone()

    if m.swapAnimation.state = "stopped"

        'Set main BG node image and hide transitioning node
        m.backdrop.uri = m.newBackdrop.uri
        m.backdrop.opacity = 0.25
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

sub onItemalphaSelected()
    if m.top.alphaSelected <> ""
        m.loadedRows = 0
        m.loadedItems = 0
        m.data = CreateObject("roSGNode", "ContentNode")
        m.itemGrid.content = m.data
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
    if m.top.parentItem.collectionType = "livetv" and m.options.view <> m.view
        if m.options.view = "tvGuide"
            m.view = "tvGuide"
            set_user_setting("display.livetv.landing", "guide")
            showTVGuide()
            return
        else
            m.view = "livetv"
            set_user_setting("display.livetv.landing", "channels")

            if m.tvGuide <> invalid
                ' Try to hide the TV Guide
                m.top.removeChild(m.tvGuide)
            end if
        end if
    end if

    if m.top.parentItem.Type = "CollectionFolder" or m.top.parentItem.Type = "Folder" or m.top.parentItem.CollectionType = "CollectionFolder"
        ' Did the user just request "Random" on a PhotoAlbum?
        if m.options.view = "singlephoto"
            set_user_setting("photos.slideshow", "false")
            set_user_setting("photos.random", "false")
        else if m.options.view = "slideshowphoto"
            set_user_setting("photos.slideshow", "true")
            set_user_setting("photos.random", "false")
        else if m.options.view = "randomphoto"
            set_user_setting("photos.random", "true")
            set_user_setting("photos.slideshow", "false")
        end if
    end if

    reload = false

    if m.top.parentItem.collectionType = "music"
        if m.options.view <> m.view
            m.view = m.options.view
            set_user_setting("display.music.view", m.view)
            reload = true
        end if
    else
        m.view = get_user_setting("display." + m.top.parentItem.Id + ".landing")
        if m.options.view <> m.view
            'reload and store new view setting
            m.view = m.options.view
            set_user_setting("display." + m.top.parentItem.Id + ".landing", m.view)
            reload = true
        end if
    end if

    if m.options.sortField <> m.sortField or m.options.sortAscending <> m.sortAscending
        m.sortField = m.options.sortField
        m.sortAscending = m.options.sortAscending
        reload = true

        'Store sort settings
        if m.sortAscending = true
            sortAscendingStr = "true"
        else
            sortAscendingStr = "false"
        end if

        if m.top.parentItem.collectionType = "livetv"
            set_user_setting("display.livetv.sortField", m.sortField)
            set_user_setting("display.livetv.sortAscending", sortAscendingStr)
        else
            set_user_setting("display." + m.top.parentItem.Id + ".sortField", m.sortField)
            set_user_setting("display." + m.top.parentItem.Id + ".sortAscending", sortAscendingStr)
        end if
    end if
    if m.options.filter <> m.filter
        m.filter = m.options.filter
        updateTitle()
        reload = true
        'Store filter setting
        if m.top.parentItem.collectionType = "livetv"
            set_user_setting("display.livetv.filter", m.options.filter)
        else
            set_user_setting("display." + m.top.parentItem.Id + ".filter", m.options.filter)
        end if
    end if
    if reload
        m.loadedRows = 0
        m.loadedItems = 0
        m.data = CreateObject("roSGNode", "ContentNode")
        m.itemGrid.content = m.data
        loadInitialItems()
    end if
    m.itemGrid.setFocus(true)
    if m.tvGuide <> invalid
        m.tvGuide.lastFocus.setFocus(true)
    end if

end sub

sub showTVGuide()
    if m.tvGuide = invalid
        m.tvGuide = createObject("roSGNode", "Schedule")
        m.top.signalBeacon("EPGLaunchInitiate") ' Required Roku Performance monitoring
        m.tvGuide.observeField("watchChannel", "onChannelSelected")
        m.tvGuide.observeField("focusedChannel", "onChannelFocused")
    end if
    m.tvGuide.filter = m.filter
    m.tvGuide.searchTerm = m.voiceBox.text
    m.top.appendChild(m.tvGuide)
    m.tvGuide.lastFocus.setFocus(true)
end sub

sub onChannelSelected(msg)
    node = msg.getRoSGNode()
    m.top.lastFocus = lastFocusedChild(node)
    if node.watchChannel <> invalid
        ' Clone the node when it's reused/update in the TimeGrid it doesn't automatically start playing
        m.top.selectedItem = node.watchChannel.clone(false)
    end if
end sub

sub onChannelFocused(msg)
    node = msg.getRoSGNode()
    m.channelFocused = node.focusedChannel
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    topGrp = m.top.findNode("itemGrid")
    searchGrp = m.top.findNode("voiceBox")

    if key = "left" and searchGrp.isinFocusChain()
        topGrp.setFocus(true)
        searchGrp.setFocus(false)
    end if
    if key = "options"
        if m.options.visible = true
            m.options.visible = false
            m.top.removeChild(m.options)
            optionsClosed()
        else
            channelSelected = m.channelFocused
            itemSelected = m.selectedFavoriteItem
            if itemSelected <> invalid
                m.options.selectedFavoriteItem = itemSelected
            end if
            if channelSelected <> invalid
                if channelSelected.type = "TvChannel"
                    m.options.selectedFavoriteItem = channelSelected
                end if
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
    else if key = "play" or key = "OK"
        markupGrid = m.top.findNode("itemGrid")
        itemToPlay = markupGrid.content.getChild(markupGrid.itemFocused)

        if itemToPlay <> invalid and (itemToPlay.type = "Movie" or itemToPlay.type = "Episode")
            m.top.quickPlayNode = itemToPlay
            return true
        else if itemToPlay <> invalid and itemToPlay.type = "Photo"
            ' Spawn photo player task
            photoPlayer = CreateObject("roSgNode", "PhotoDetails")
            photoPlayer.items = markupGrid
            photoPlayer.itemIndex = markupGrid.itemFocused
            m.global.sceneManager.callfunc("pushScene", photoPlayer)
            return true
        end if
    else if key = "left" and topGrp.isinFocusChain()
        m.top.alphaActive = true
        topGrp.setFocus(false)
        alpha = m.alpha.getChild(0).findNode("Alphamenu")
        alpha.setFocus(true)
        return true

    else if key = "right" and m.Alpha.isinFocusChain()
        m.top.alphaActive = false
        m.Alpha.setFocus(false)
        m.Alpha.visible = true
        topGrp.setFocus(true)
        return true
    else if key = "replay" and topGrp.isinFocusChain()
        if m.resetGrid = true
            m.itemGrid.animateToItem = 0
        else
            m.itemGrid.jumpToItem = 0
        end if
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

sub updateTitle()
    if m.filter = "All"
        m.top.overhangTitle = m.top.parentItem.title
    else if m.filter = "Favorites"
        m.top.overhangTitle = m.top.parentItem.title + " " + tr("(Favorites)")
    end if
    if m.voiceBox.text <> ""
        m.top.overhangTitle = m.top.parentItem.title + tr(" (Filtered by ") + m.loadItemsTask.searchTerm + ")"
    end if
    if m.top.alphaSelected <> ""
        m.top.overhangTitle = m.top.parentItem.title + tr(" (Filtered by ") + m.loadItemsTask.nameStartsWith + ")"
    end if

    if m.view = "music-artist"
        m.top.overhangTitle = "%s (%s)".Format(m.top.parentItem.title, tr("Artists"))
    else if m.view = "music-album"
        m.top.overhangTitle = "%s (%s)".Format(m.top.parentItem.title, tr("Albums"))
    end if

    if m.options.view = "Networks" or m.view = "Networks"
        m.top.overhangTitle = "%s (%s)".Format(m.top.parentItem.title, tr("Networks"))
    end if
    if m.options.view = "Studios" or m.view = "Studios"
        m.top.overhangTitle = "%s (%s)".Format(m.top.parentItem.title, tr("Studios"))
    end if
    if m.options.view = "Genres" or m.view = "Genres"
        m.top.overhangTitle = "%s (%s)".Format(m.top.parentItem.title, tr("Genres"))
    end if
    actInt = m.itemGrid.itemFocused + 1
    if m.showItemCount and m.loadItemsTask.totalRecordCount > 0
        m.top.overhangTitle += " (" + tr("%1 of %2").Replace("%1", actInt.toStr()).Replace("%2", m.loadItemsTask.totalRecordCount.toStr()) + ")"
    end if

end sub
