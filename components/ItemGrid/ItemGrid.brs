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
    m.itemGrid.observeField("AlphaSelected", "onItemAlphaSelected")
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
end sub

'
'Load initial set of Data
sub loadInitialItems()

    if m.top.parentItem.backdropUrl <> invalid
        SetBackground(m.top.parentItem.backdropUrl)
    end if

    ' Read view/sort/filter settings
    if m.top.parentItem.collectionType = "livetv"
        ' Translate between app and server nomenclature
        viewSetting = get_user_setting("display.livetv.landing")
        if viewSetting = "guide"
            m.view = "tvGuide"
        else
            m.view = "livetv"
        end if
        m.sortField = get_user_setting("display.livetv.sortField")
        sortAscendingStr = get_user_setting("display.livetv.sortAscending")
        m.filter = get_user_setting("display.livetv.filter")
    else
        m.view = invalid
        m.sortField = get_user_setting("display." + m.top.parentItem.Id + ".sortField")
        sortAscendingStr = get_user_setting("display." + m.top.parentItem.Id + ".sortAscending")
        m.filter = get_user_setting("display." + m.top.parentItem.Id + ".filter")
    end if

    if m.sortField = invalid then m.sortField = "SortName"
    if m.filter = invalid then m.filter = "All"

    if sortAscendingStr = invalid or sortAscendingStr = "true"
        m.sortAscending = true
    else
        m.sortAscending = false
    end if

    m.loadItemsTask.nameStartsWith = m.top.AlphaSelected
    m.emptyText.visible = false

    updateTitle()

    m.loadItemsTask.itemId = m.top.parentItem.Id
    m.loadItemsTask.sortField = m.sortField
    m.loadItemsTask.sortAscending = m.sortAscending
    m.loadItemsTask.filter = m.filter
    m.loadItemsTask.startIndex = 0

    if m.top.parentItem.collectionType = "movies"
        m.loadItemsTask.itemType = "Movie"
    else if m.top.parentItem.collectionType = "tvshows"
        m.loadItemsTask.itemType = "Series"
    else if m.top.parentItem.collectionType = "livetv"
        m.loadItemsTask.itemType = "LiveTV"

        'For LiveTV, we want to "Fit" the item images, not zoom
        m.top.imageDisplayMode = "scaleToFit"

        if get_user_setting("display.livetv.landing") = "guide" and m.options.view <> "livetv"
            showTvGuide()
        end if

    else if m.top.parentItem.collectionType = "CollectionFolder" or m.top.parentItem.type = "CollectionFolder" or m.top.parentItem.collectionType = "boxsets" or m.top.parentItem.Type = "Folder" or m.top.parentItem.Type = "Channel"
        ' Non-recursive, to not show subfolder contents
        m.loadItemsTask.recursive = false
    else if m.top.parentItem.collectionType = "Channel"
        m.top.imageDisplayMode = "scaleToFit"
    else
        print "[ItemGrid] Unknown Type: " m.top.parentItem
    end if

    m.loadItemsTask.observeField("content", "ItemDataLoaded")
    m.loadItemsTask.control = "RUN"

    SetUpOptions()

end sub

' Data to display when options button selected
sub SetUpOptions()

    options = {}
    options.filter = []
    options.favorite = []

    'Movies
    if m.top.parentItem.collectionType = "movies"
        options.views = [
            { "Title": tr("Movies"), "Name": "movies" },
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
        'Boxsets
    else if m.top.parentItem.collectionType = "boxsets"
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
        'TV Shows
    else if m.top.parentItem.collectionType = "tvshows"
        options.views = [{ "Title": tr("Shows"), "Name": "shows" }]
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
        'Live TV
    else if m.top.parentItem.collectionType = "livetv"
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
    else if m.top.parentItem.collectionType = "photoalbum" or m.top.parentItem.collectionType = "photo" or m.top.parentItem.collectionType = "homevideos"
        ' For some reason, my photo library shows up as "homevideos", maybe because it has some mp4 mixed in with the jpgs?

        ' TODO/FIXME: Show shuffle options once implemented
        ' options.views = [
        '     { "Title": tr("Don't Shuffle"), "Name": "singlephoto"}
        '     { "Title": tr("Shuffle"), "Name": "shufflephoto"}
        ' ]
        options.views = []
        options.sort = []
        options.filter = []
    else
        options.views = [
            { "Title": tr("Default"), "Name": "default" }
        ]
        options.sort = [
            { "Title": tr("TITLE"), "Name": "SortName" }
        ]
        options.filter = []
    end if

    for each o in options.views
        if o.Name = m.view
            o.Selected = true
            o.Ascending = m.sortAscending
            m.options.view = o.Name
        end if
    end for

    for each o in options.sort
        if o.Name = m.sortField
            o.Selected = true
            o.Ascending = m.sortAscending
            m.options.sortField = o.Name
        end if
    end for

    for each o in options.filter
        if o.Name = m.filter
            o.Selected = true
            m.options.filter = o.Name
        end if
    end for

    ' for each o in options.favorite
    '     if o.Name = m.favorite
    '         m.options.favorite = o.Name
    '     end if
    ' end for

    m.options.options = options

end sub


'
'Handle loaded data, and add to Grid
sub ItemDataLoaded(msg)

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

    ' Load more data if focus is within last 3 rows, and there are more items to load
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

sub onItemAlphaSelected()
    m.loadedRows = 0
    m.loadedItems = 0
    m.data = CreateObject("roSGNode", "ContentNode")
    m.itemGrid.content = m.data
    loadInitialItems()
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

    if m.top.parentItem.Type = "CollectionFolder" or m.top.parentItem.CollectionType = "CollectionFolder"
        ' Did the user just request "Shuffle" on a PhotoAlbum?
        if m.options.view = "singlephoto"
            ' TODO/FIXME: Stop shuffling here
            print "TODO/FIXME: Stop any shuffling here"
        else if m.options.view = "shufflephoto"
            ' TODO/FIXME: Start shuffling here
            print "TODO/FIXME: Start shuffle here"
        end if
    end if

    reload = false
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
        end if
    else if key = "play" or key = "OK"
        markupGrid = m.top.getChild(2)
        itemToPlay = markupGrid.content.getChild(markupGrid.itemFocused)

        if itemToPlay <> invalid and (itemToPlay.type = "Movie" or itemToPlay.type = "Episode")
            m.top.quickPlayNode = itemToPlay
            return true
        else if itemToPlay <> invalid and itemToPlay.type = "Photo"
            ' Spawn photo player task
            photoPlayer = CreateObject("roSgNode", "PhotoPlayerTask")
            photoPlayer.itemContent = itemToPlay
            photoPlayer.control = "RUN"
            return true
        end if
    else if key = "left" and topGrp.isinFocusChain()
        topGrp.setFocus(false)
        alpha = m.Alpha.getChild(0).findNode("Alphamenu")
        alpha.setFocus(true)
        return true
    else if key = "right" and m.Alpha.isinFocusChain()
        m.Alpha.setFocus(false)
        m.Alpha.visible = true
        topGrp.setFocus(true)
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

    if m.top.AlphaSelected <> ""
        m.top.overhangTitle = m.top.parentItem.title + " " + tr("(Filtered)")
    end if

    actInt = m.itemGrid.itemFocused + 1
    if m.showItemCount and m.loadItemsTask.totalRecordCount > 0
        m.top.overhangTitle += " (" + tr("%1 of %2").Replace("%1", actInt.toStr()).Replace("%2", m.loadItemsTask.totalRecordCount.toStr()) + ")"
    end if

end sub
