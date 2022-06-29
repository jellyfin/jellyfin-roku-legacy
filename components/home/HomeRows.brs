sub init()
    m.top.itemComponentName = "HomeItem"
    ' how many rows are visible on the screen
    m.top.numRows = 2

    m.top.rowFocusAnimationStyle = "fixedFocusWrap"
    m.top.vertFocusAnimationStyle = "fixedFocus"

    m.top.showRowLabel = [true]
    m.top.rowLabelOffset = [0, 20]
    m.top.showRowCounter = [true]

    m.latestMediaCount = 0
    m.latestMediaInt = 0
    m.latestMediaNode = ""
    m.sectionCount = 0
    m.sectionIgnores = []

    updateSize()

    m.top.setfocus(true)

    m.top.observeField("rowItemSelected", "itemSelected")

    ' Load the Libraries from API via task
    m.LoadLibrariesTask = createObject("roSGNode", "LoadItemsTask")
    m.LoadLibrariesTask.observeField("content", "onLibrariesLoaded")

    m.LoadHomeSectionTask = createObject("roSGNode", "LoadItemsTask")

    m.LoadMyMediaTask = createObject("roSGNode", "LoadItemsTask")
    m.LoadMyMediaTask.itemsToLoad = "libraries"
    m.LoadMyMediaSmallTask = createObject("roSGNode", "LoadItemsTask")
    m.LoadMyMediaSmallTask.itemsToLoad = "libraries"
    m.LoadLatestMediaTask = createObject("roSGNode", "LoadItemsTask")
    m.LoadContinueVideoTask = createObject("roSGNode", "LoadItemsTask")
    m.LoadContinueVideoTask.itemsToLoad = "continueVideo"
    m.LoadContinueAudioTask = createObject("roSGNode", "LoadItemsTask")
    m.LoadContinueAudioTask.itemsToLoad = "continueAudio"
    m.LoadContinueBookTask = createObject("roSGNode", "LoadItemsTask")
    m.LoadContinueBookTask.itemsToLoad = "continueBook"
    m.LoadNextUpTask = createObject("roSGNode", "LoadItemsTask")
    m.LoadNextUpTask.itemsToLoad = "nextUp"
    m.LoadOnNowTask = createObject("roSGNode", "LoadItemsTask")
    m.LoadOnNowTask.itemsToLoad = "onNow"
end sub

sub loadLibraries()
    m.LoadLibrariesTask.control = "RUN"
end sub

sub updateSize()
    m.top.translation = [111, 180]
    itemHeight = 380

    'Set width of Rows to cut off at edge of Safe Zone
    m.top.itemSize = [1703, itemHeight]

    ' spacing between rows
    m.top.itemSpacing = [0, 55]

    ' spacing between items in a row
    m.top.rowItemSpacing = [20, 0]

    m.top.visible = true
end sub

sub onLibrariesLoaded()
    m.LoadHomeSectionTask.observeField("content", "loadHomeSections")
    m.LoadHomeSectionTask.control = "RUN"
end sub

sub loadHomeSections()
    m.libraryData = m.LoadLibrariesTask.content
    m.LoadLibrariesTask.unobserveField("content")
    content = CreateObject("roSGNode", "ContentNode")
    m.top.content = content

    setLatestMediaCount()
    createHoldingChildren()

    m.latestMediaInt = getHomeSectionInt("latestmedia")
    m.sectionCount = getHomeSectionCount()

    for i = 0 to 6
        content = m.top.content
        homesection = get_user_setting(Substitute("display.homesection{0}", i.toStr()))

        if homesection = "smalllibrarytiles"
            m.LoadMyMediaTask.observeField("content", "updateMyMedia")
            m.LoadMyMediaTask.control = "RUN"
            m.LoadMyMediaTask.observeField("state", "onUpdateMyMediaComplete")
        else if homesection = "librarybuttons"
            m.LoadMyMediaSmallTask.observeField("content", "updateMyMediaSmall")
            m.LoadMyMediaSmallTask.control = "RUN"
            m.LoadMyMediaSmallTask.observeField("state", "onUpdateMyMediaSmallComplete")
        else if homesection = "latestmedia"
            m.LoadLatestMediaTask.observeField("content", "updateLatestMedia")
            m.LoadLatestMediaTask.control = "RUN"
            m.LoadLatestMediaTask.observeField("state", "onUpdateLatestMediaComplete")
        else if homesection = "resume"
            m.LoadContinueVideoTask.observeField("content", "updateContinueVideoItems")
            m.LoadContinueVideoTask.control = "RUN"
            m.LoadContinueVideoTask.observeField("state", "onUpdateContinueVideoItemsComplete")
        else if homesection = "resumeaudio"
            m.LoadContinueAudioTask.observeField("content", "updateContinueAudioItems")
            m.LoadContinueAudioTask.control = "RUN"
            m.LoadContinueAudioTask.observeField("state", "onUpdateContinueAudioItemsComplete")
        else if homesection = "resumebook"
            m.LoadContinueBookTask.observeField("content", "updateContinueBookItems")
            m.LoadContinueBookTask.control = "RUN"
            m.LoadContinueBookTask.observeField("state", "onUpdateContinueBookItemsComplete")
        else if homesection = "nextup"
            m.LoadNextUpTask.observeField("content", "updateNextUpItems")
            m.LoadNextUpTask.control = "RUN"
            m.LoadNextUpTask.observeField("state", "onUpdateNextUpItemsComplete")
        else if homesection = "livetv"
            m.LoadOnNowTask.observeField("content", "updateOnNowItems")
            m.LoadOnNowTask.control = "RUN"
            m.LoadOnNowTask.observeField("state", "onUpdateOnNowItemsComplete")
        else if homesection = "none"
            child = i + 1
            latest_media_int = m.latestMediaInt
            latestMediaCount = m.latestMediaCount - 1
            if latest_media_int < i + 1 and latestMediaCount > 0
                child = child + latestMediaCount
            end if
            removeHoldingChild(child)
        end if
        m.top.content = content
    end for

    ' consider home screen loaded when above rows are loaded
    if m.global.app_loaded = false
        m.top.signalBeacon("AppLaunchComplete") ' Roku Performance monitoring
        m.global.app_loaded = true
    end if
end sub

sub setLatestMediaCount()
    userConfig = m.top.userConfig
    filteredLatest = filterNodeArray(m.libraryData, "id", userConfig.LatestItemsExcludes)
    latest_count = 0

    ' Have to filter the orderedViews because Brightscript is awesome
    userConfig = ParseJson(get_user_setting("display.userConfig"))
    orderedViews = userConfig.Configuration.OrderedViews
    filteredOrderedViews = []
    if userConfig <> invalid
        if orderedViews <> invalid
            for i = 0 to orderedViews.count() - 1
                for j = 0 to filteredLatest.count() - 1
                    if filteredLatest[j].id = orderedViews[i]
                        if filteredLatest[j].collectionType <> "boxsets" and filteredLatest[j].collectionType <> "livetv" and filteredLatest[j].collectionType <> "CollectionFolder" and filteredLatest[j].collectionType <> "folders"
                            filteredOrderedViews.push(orderedViews[i])
                            exit for
                        end if
                    end if
                end for
            end for
        end if
    end if
    if filteredOrderedViews.count() <> 0
        for i = 0 to filteredOrderedViews.count() - 1
            for each lib in filteredLatest
                if filteredOrderedViews[i] = lib.id
                    if lib.collectionType <> "boxsets" and lib.collectionType <> "livetv" and lib.collectionType <> "CollectionFolder" and lib.collectionType <> "folders"
                        latest_count = latest_count + 1
                    end if
                end if
            end for
        end for
    else
        latest_count = 0
        for each lib in filteredLatest
            if lib.collectionType <> "boxsets" and lib.collectionType <> "livetv" and lib.collectionType <> "CollectionFolder" and lib.collectionType <> "folders"
                latest_count = latest_count + 1
            end if
        end for
    end if
    m.latestMediaCount = latest_count
end sub

sub onUpdateMyMediaComplete(event)
    data = event.GetData()
    ignores = m.sectionIgnores
    if data = "stop"
        itemData = m.LoadMyMediaTask.content
        if itemData.count() = 0
            ignores.push("smalllibrarytiles")
            m.sectionIgnores = ignores
            section = getHomeSectionInt("smalllibrarytiles")
            index_section = section + 1
            row_index = getRowIndex(Substitute("Loading Section {0}...", index_section.toStr()))
            if row_index <> invalid
                homeRows = m.top.content
                row = homeRows.getChild(row_index)
                homeRows.removeChild(row)
            end if
        end if
        rebuildItemArray()
    end if
end sub

sub onUpdateMyMediaSmallComplete(event)
    data = event.GetData()
    ignores = m.sectionIgnores
    if data = "stop"
        itemData = m.LoadMyMediaSmallTask.content
        if itemData.count() = 0
            ignores.push("librarybuttons")
            m.sectionIgnores = ignores
            section = getHomeSectionInt("librarybuttons")
            index_section = section + 1
            row_index = getRowIndex(Substitute("Loading Section {0}...", index_section.toStr()))
            if row_index <> invalid
                homeRows = m.top.content
                row = homeRows.getChild(row_index)
                homeRows.removeChild(row)
            end if
        end if
        rebuildItemArray()
    end if
end sub

sub onUpdateLatestMediaComplete(event)
    data = event.GetData()
    ignores = m.sectionIgnores
    if data = "stop"
        itemData = m.LoadLatestMediaTask.content
        if itemData.count() = 0
            ignores.push("latestmedia")
            m.sectionIgnores = ignores
            section = getHomeSectionInt("latestmedia")
            index_section = section + 1
            row_index = getRowIndex(Substitute("Loading Section {0}...", index_section.toStr()))
            if row_index <> invalid
                homeRows = m.top.content
                row = homeRows.getChild(row_index)
                homeRows.removeChild(row)
            end if
        end if
        rebuildItemArray()
    end if
end sub

sub onUpdateContinueVideoItemsComplete(event)
    data = event.GetData()
    ignores = m.sectionIgnores
    if data = "stop"
        itemData = m.LoadContinueVideoTask.content
        if itemData.count() = 0
            ignores.push("resume")
            m.sectionIgnores = ignores
            section = getHomeSectionInt("resume")
            index_section = section + 1
            row_index = getRowIndex(Substitute("Loading Section {0}...", index_section.toStr()))
            if row_index <> invalid
                homeRows = m.top.content
                row = homeRows.getChild(row_index)
                homeRows.removeChild(row)
            end if
        end if
        rebuildItemArray()
    end if
end sub

sub onUpdateContinueAudioItemsComplete(event)
    data = event.GetData()
    ignores = m.sectionIgnores
    if data = "stop"
        itemData = m.LoadContinueAudioTask.content
        if itemData.count() = 0
            ignores.push("resumeaudio")
            m.sectionIgnores = ignores
            section = getHomeSectionInt("resumeaudio")
            index_section = section + 1
            row_index = getRowIndex(Substitute("Loading Section {0}...", index_section.toStr()))
            if row_index <> invalid
                homeRows = m.top.content
                row = homeRows.getChild(row_index)
                homeRows.removeChild(row)
            end if
        end if
        rebuildItemArray()
    end if
end sub

sub onUpdateContinueBookItemsComplete(event)
    data = event.GetData()
    ignores = m.sectionIgnores
    if data = "stop"
        itemData = m.LoadContinueBookTask.content
        if itemData.count() = 0
            ignores.push("resumebook")
            m.sectionIgnores = ignores
            section = getHomeSectionInt("resumebook")
            index_section = section + 1
            row_index = getRowIndex(Substitute("Loading Section {0}...", index_section.toStr()))
            if row_index <> invalid
                homeRows = m.top.content
                row = homeRows.getChild(row_index)
                homeRows.removeChild(row)
            end if
        end if
        rebuildItemArray()
    end if
end sub

sub onUpdateNextUpItemsComplete(event)
    data = event.GetData()
    ignores = m.sectionIgnores
    if data = "stop"
        itemData = m.LoadNextUpTask.content
        if itemData.count() = 0
            ignores.push("nextup")
            m.sectionIgnores = ignores
            section = getHomeSectionInt("nextup")
            index_section = section + 1
            row_index = getRowIndex(Substitute("Loading Section {0}...", index_section.toStr()))
            if row_index <> invalid
                homeRows = m.top.content
                row = homeRows.getChild(row_index)
                homeRows.removeChild(row)
            end if
        end if
        rebuildItemArray()
    end if
end sub

sub onUpdateOnNowItemsComplete(event)
    data = event.GetData()
    ignores = m.sectionIgnores
    if data = "stop"
        itemData = m.LoadOnNowTask.content
        if itemData.count() = 0
            ignores.push("livetv")
            m.sectionIgnores = ignores
            section = getHomeSectionInt("livetv")
            index_section = section + 1
            row_index = getRowIndex(Substitute("Loading Section {0}...", index_section.toStr()))
            if row_index <> invalid
                homeRows = m.top.content
                row = homeRows.getChild(row_index)
                homeRows.removeChild(row)
            end if
        end if
        rebuildItemArray()
    end if
end sub

sub createHoldingChildren()
    ' Creating children to fill later on.
    ' Welcome Children - Mose
    home_section_count = getHomeSectionCount()
    content = m.top.content
    for i = 1 to home_section_count
        homeSectionHold = CreateObject("roSGNode", "HomeRow")
        homeSectionHold.title = Substitute("Loading Section {0}...", i.toStr())
        content.insertChild(homeSectionHold, i)
    end for
    m.top.content = content
end sub

sub removeHoldingChild(child as integer)
    content = m.top.content
    row_index = getRowIndex(Substitute("Loading Section {0}...", child.toStr()))
    if row_index <> invalid
        row = content.getChild(row_index)
        content.removeChild(row)
        m.top.content = content
    end if
end sub

sub rebuildItemArray()
    section_count = getHomeSectionCount()
    ignores = m.sectionIgnores
    m.top.rowItemSize = []
    newSizeArray = []
    homesections = []
    for i = 0 to section_count
        homesection = get_user_setting(Substitute("display.homesection{0}", i.toStr()))
        if homesection <> invalid
            homesections.push(homesection)
        end if
    end for
    for i = 0 to homesections.count()
        ' Loop through ignores
        if ignores <> invalid and ignores.count() > 0
            for each ignore in ignores
                if ignore = homesections[i]
                    homesections.delete(i)
                    i--
                end if
            end for
        end if
    end for
    for each homesection in homesections
        if homesection <> invalid
            if homesection = "latestmedia"
                userConfig = m.top.userConfig
                filteredLatest = filterNodeArray(m.libraryData, "id", userConfig.LatestItemsExcludes)
                for each lib in filteredLatest
                    if lib.collectionType <> "boxsets" and lib.collectionType <> "livetv"
                        itemSize = [200, 270]
                        newSizeArray.push(itemSize)
                    end if
                end for
            end if
            if homesection <> "latestmedia" and homesection <> "none"
                itemSize = [464, 261]
                if homesection = "librarybuttons"
                    itemSize = [464, 100]
                else if homesection = "resumebook" or homesection = "livetv"
                    itemSize = [200, 270]
                end if
                newSizeArray.push(itemSize)
            end if
        end if
    end for
    for each size in newSizeArray
        ' print "SIZE: " size
    end for
    m.top.rowItemSize = newSizeArray
end sub

sub updateHomeRows()
    m.LoadContinueVideoTask.observeField("content", "loadHomeSection0")
    m.LoadContinueVideoTask.control = "RUN"
end sub

function getHomeSectionInt(section as string)
    home_section_count = getHomeSectionCount()
    for i = 0 to home_section_count
        homesection = get_user_setting(Substitute("display.homesection{0}", i.toStr()))
        if homesection <> invalid
            if homesection = section
                if section = "latestmedia"
                    return i
                end if
                latest_media_int = m.latestMediaInt
                latestMediaCount = m.latestMediaCount - 1
                if latest_media_int < i
                    if latestMediaCount > 0
                        i = i + latestMediaCount
                    end if
                end if
                return i
            end if
        end if
    end for
    return -1
end function

function getHomeSectionCount()
    latest_media_count = m.latestMediaCount
    section_count = 0
    for i = 0 to 6
        homesection = get_user_setting(Substitute("display.homesection{0}", i.toStr()))
        if homesection <> "latestmedia" and homesection <> "none"
            section_count += 1
        end if
    end for
    return section_count + latest_media_count
end function

sub updateMyMedia()
    homeRows = m.top.content
    section = getHomeSectionInt("smalllibrarytiles")
    m.LoadMyMediaTask.control = "RUN"
    itemData = m.LoadMyMediaTask.content
    m.LoadMyMediaTask.unobserveField("content")

    itemSize = [464, 261]

    latest_media_int = m.latestMediaInt
    latestMediaCount = m.latestMediaCount - 1
    if latest_media_int < section
        if latestMediaCount > 0
            section = section + latestMediaCount
        end if
    end if

    index_section = section + 1
    row_index = getRowIndex(Substitute("Loading Section {0}...", index_section.toStr()))
    if row_index <> invalid
        row = homeRows.getChild(row_index)
        row.title = tr("My Media")
        row.id = section
        for each item in itemData
            item.usePoster = true
            item.imageWidth = 464
            row.appendChild(item)
        end for
        updateSizeArray(itemSize, section + latestMediaCount, "replace")
        row.update(row, false)
    end if
end sub

sub updateMyMediaSmall()
    homeRows = m.top.content
    section = getHomeSectionInt("librarybuttons")
    itemData = m.LoadMyMediaSmallTask.content
    m.LoadMyMediaSmallTask.unobserveField("content")

    itemSize = [464, 100]

    latest_media_int = m.latestMediaInt
    latestMediaCount = m.latestMediaCount - 1
    if latest_media_int < section
        if latestMediaCount > 0
            section = section + latestMediaCount
        end if
    end if

    index_section = section + 1
    row_index = getRowIndex(Substitute("Loading Section {0}...", index_section.toStr()))
    if row_index <> invalid
        row = homeRows.getChild(row_index)
        row.title = tr("My Media")
        for each item in itemData
            item.usePoster = false
            item.isSmall = true
            item.iconUrl = ""
            row.appendChild(item)
        end for
        updateSizeArray(itemSize, section + latestMediaCount, "replace")
        row.update(row, false)
    end if
end sub

sub updateLatestMedia()
    userConfig = m.top.userConfig
    filteredLatest = filterNodeArray(m.libraryData, "id", userConfig.LatestItemsExcludes)
    latest_count = 0

    ' Have to filter the orderedViews because Brightscript is awesome
    userConfig = ParseJson(get_user_setting("display.userConfig"))
    orderedViews = userConfig.Configuration.OrderedViews
    filteredOrderedViews = []
    if userConfig <> invalid
        if orderedViews <> invalid
            for i = 0 to orderedViews.count() - 1
                for j = 0 to filteredLatest.count() - 1
                    if filteredLatest[j].id = orderedViews[i]
                        if filteredLatest[j].collectionType <> "boxsets" and filteredLatest[j].collectionType <> "livetv" and filteredLatest[j].collectionType <> "CollectionFolder" and filteredLatest[j].collectionType <> "folders"
                            filteredOrderedViews.push(orderedViews[i])
                            exit for
                        end if
                    end if
                end for
            end for
        end if
    end if
    if filteredOrderedViews.count() <> 0
        for i = 0 to filteredOrderedViews.count() - 1
            for each lib in filteredLatest
                if filteredOrderedViews[i] = lib.id
                    if lib.collectionType <> "boxsets" and lib.collectionType <> "livetv" and lib.collectionType <> "CollectionFolder" and lib.collectionType <> "folders"
                        latest_count = latest_count + 1
                        loadLatest = createObject("roSGNode", "LoadItemsTask")
                        loadLatest.itemsToLoad = "latest"
                        loadLatest.itemId = lib.id
                        loadLatest.nodeNumber = i

                        metadata = { "title": lib.name }
                        metadata.Append({ "contentType": lib.json.CollectionType })
                        loadLatest.metadata = metadata

                        loadLatest.observeField("content", "updateLatestItems")
                        loadLatest.control = "RUN"
                    end if
                end if
            end for
        end for
    else
        latest_count = 0
        for each lib in filteredLatest
            if lib.collectionType <> "boxsets" and lib.collectionType <> "livetv" and lib.collectionType <> "CollectionFolder" and lib.collectionType <> "folders"
                loadLatest = createObject("roSGNode", "LoadItemsTask")
                loadLatest.itemsToLoad = "latest"
                loadLatest.itemId = lib.id
                loadLatest.nodeNumber = latest_count
                latest_count = latest_count + 1

                metadata = { "title": lib.name }
                metadata.Append({ "contentType": lib.json.CollectionType })
                loadLatest.metadata = metadata

                loadLatest.observeField("content", "updateLatestItems")
                loadLatest.control = "RUN"
            end if
        end for
    end if
end sub

sub updateContinueVideoItems()
    homeRows = m.top.content
    section = getHomeSectionInt("resume")
    itemData = m.LoadContinueVideoTask.content
    m.LoadContinueVideoTask.unobserveField("content")

    itemSize = [464, 331]

    latest_media_int = m.latestMediaInt
    latestMediaCount = m.latestMediaCount - 1
    if latest_media_int < section
        if latestMediaCount > 0
            section = section + latestMediaCount
        end if
    end if

    index_section = section + 1
    row_index = getRowIndex(Substitute("Loading Section {0}...", index_section.toStr()))
    if row_index <> invalid
        row = homeRows.getChild(row_index)
        row.title = tr("Continue Watching")
        item_count = itemData.count()
        if item_count > 50
            item_count = 50
        end if
        if item_count = 0
            homeRows.removeChild(row)
        end if
        for i = 0 to item_count
            if itemData[i] <> invalid
                itemData[i].usePoster = true
                itemData[i].imageWidth = 464
                itemData[i].stretch = true
                row.appendChild(itemData[i])
            end if
        end for

        updateSizeArray(itemSize, section + latestMediaCount, "replace")
        row.update(row, false)
    end if
end sub

sub updateContinueAudioItems()
    homeRows = m.top.content
    section = getHomeSectionInt("resumeaudio")
    itemData = m.LoadContinueAudioTask.content
    m.LoadContinueAudioTask.unobserveField("content")

    itemSize = [464, 331]

    latest_media_int = m.latestMediaInt
    latestMediaCount = m.latestMediaCount - 1
    if latest_media_int < section
        if latestMediaCount > 0
            section = section + latestMediaCount
        end if
    end if

    index_section = section + 1
    row_index = getRowIndex(Substitute("Loading Section {0}...", index_section.toStr()))
    if row_index <> invalid
        row = homeRows.getChild(row_index)
        row.title = tr("Continue Listening")
        item_count = itemData.count()
        if item_count > 1000
            item_count = 1000
        end if
        if item_count = 0
            homeRows.removeChild(row)
        end if
        for i = 0 to item_count
            if itemData[i] <> invalid
                itemData[i].usePoster = true
                itemData[i].imageWidth = 464
                row.appendChild(itemData[i])
            end if
        end for

        updateSizeArray(itemSize, section + latestMediaCount, "replace")
        row.update(row, false)
    end if
end sub

sub updateContinueBookItems()
    homeRows = m.top.content
    section = getHomeSectionInt("resumebook")
    itemData = m.LoadContinueBookTask.content
    m.LoadContinueBookTask.unobserveField("content")

    itemSize = [200, 270]

    latest_media_int = m.latestMediaInt
    latestMediaCount = m.latestMediaCount - 1
    if latest_media_int < section
        if latestMediaCount > 0
            section = section + latestMediaCount
        end if
    end if

    index_section = section + 1
    row_index = getRowIndex(Substitute("Loading Section {0}...", index_section.toStr()))
    if row_index <> invalid
        row = homeRows.getChild(row_index)
        row.title = tr("Continue Reading")
        item_count = itemData.count()
        if item_count > 1000
            item_count = 1000
        end if
        if item_count = 0
            homeRows.removeChild(row)
        end if
        for i = 0 to item_count
            if itemData[i] <> invalid
                itemData[i].usePoster = true
                itemData[i].imageWidth = 200
                row.appendChild(itemData[i])

            end if
        end for

        row.update(row, false)
        updateSizeArray(itemSize, section + latestMediaCount, "replace")
    end if
end sub

sub updateNextUpItems()
    itemData = m.LoadNextUpTask.content
    m.LoadNextUpTask.unobserveField("content")

    itemSize = [464, 331]

    homeRows = m.top.content
    section = getHomeSectionInt("nextup")

    latest_media_int = m.latestMediaInt
    latestMediaCount = m.latestMediaCount - 1
    if latest_media_int < section
        if latestMediaCount > 0
            section = section + latestMediaCount
        end if
    end if

    index_section = section + 1
    row_index = getRowIndex(Substitute("Loading Section {0}...", index_section.toStr()))
    if row_index <> invalid
        row = homeRows.getChild(row_index)
        row.title = tr("Next Up") + " >"
        item_count = itemData.count()
        if item_count > 1000
            item_count = 1000
        end if
        if item_count = 0
            homeRows.removeChild(row)
        end if
        for i = 0 to item_count
            if itemData[i] <> invalid
                itemData[i].usePoster = false
                itemData[i].imageWidth = 464
                row.appendChild(itemData[i])
            end if
        end for

        updateSizeArray(itemSize, section + latestMediaCount, "replace")
        row.update(row, false)
    end if
end sub

sub updateLatestItems(msg)
    itemData = msg.GetData()

    node = msg.getRoSGNode()
    node.unobserveField("content")

    homeRows = m.top.content
    section = getHomeSectionInt("latestmedia")
    node_index = node.nodeNumber

    index_section = section + 1
    index_section_latest = index_section + node_index
    row_index = getRowIndex(Substitute("Loading Section {0}...", index_section_latest.toStr()))
    if row_index <> invalid
        row = homeRows.getChild(row_index)
        item_count = itemData.count()
        if item_count > 1000
            item_count = 1000
        end if
        if item_count = 0
            homeRows.removeChild(row)
        end if
        for i = 0 to item_count
            if itemData[i] <> invalid
                row.title = tr("Latest in") + " " + node.metadata.title + " >"
                itemData[i].usePoster = true
                itemData[i].imageWidth = 200
                row.appendChild(itemData[i])
            end if
        end for
        row.update(row, false)
    end if
end sub

sub updateOnNowItems()
    itemData = m.LoadOnNowTask.content
    m.LoadOnNowTask.unobserveField("content")

    itemSize = [200, 270]

    homeRows = m.top.content
    section = getHomeSectionInt("livetv")
    latestMediaCount = m.latestMediaCount - 1

    index_section = section + 1
    row_index = getRowIndex(Substitute("Loading Section {0}...", index_section.toStr()))
    if row_index <> invalid
        row = homeRows.getChild(row_index)
        row.title = tr("On Now")
        item_count = itemData.count()
        if item_count > 1000
            item_count = 1000
        end if
        if item_count = 0
            homeRows.removeChild(row)
        end if
        for i = 0 to item_count
            if itemData[i] <> invalid
                itemData[i].usePoster = true
                itemData[i].imageWidth = 200
                row.appendChild(itemData[i])
            end if
        end for
        updateSizeArray(itemSize, section + latestMediaCount, "replace")
        row.update(row, false)
    end if
end sub

function getRowIndex(rowTitle as string)
    rowIndex = invalid
    content = m.top.content
    if content <> invalid
        tmpRow = m.top.content
        for i = 0 to content.getChildCount() - 1
            tmpRow = content.getChild(i)
            sub_str = Instr(1, tmpRow.title, rowTitle)
            if tmpRow.title = rowTitle or sub_str > 0
                rowIndex = i
                exit for
            end if
        end for
    end if
    return rowIndex
end function

sub updateSizeArray(rowItemSize, rowIndex = invalid, action = "insert")
    sizeArray = m.top.rowItemSize
    ' append by default
    if rowIndex = invalid
        rowIndex = sizeArray.count()
    end if

    newSizeArray = []
    for i = 0 to sizeArray.count()
        if rowIndex = i
            if action = "replace"
                newSizeArray.push(rowItemSize)
            else if action = "insert"
                newSizeArray.push(rowItemSize)
                if sizeArray[i] <> invalid
                    newSizeArray.push(sizeArray[i])
                end if
            end if
        else if sizeArray[i] <> invalid
            newSizeArray.push(sizeArray[i])
        end if
    end for
    if newSizeArray.count() = 0
        newSizeArray.push(rowItemSize)
    end if
    m.top.rowItemSize = newSizeArray
end sub

sub deleteFromSizeArray(rowIndex)
    updateSizeArray([0, 0], rowIndex, "delete")
end sub

sub itemSelected()
    m.top.selectedItem = m.top.content.getChild(m.top.rowItemSelected[0]).getChild(m.top.rowItemSelected[1])
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    handled = false
    if press
        if key = "play"
            itemToPlay = m.top.content.getChild(m.top.rowItemFocused[0]).getChild(m.top.rowItemFocused[1])
            if itemToPlay <> invalid and (itemToPlay.type = "Movie" or itemToPlay.type = "Episode")
                m.top.quickPlayNode = itemToPlay
            end if
            handled = true
        end if

        if key = "replay"
            m.top.jumpToRowItem = [m.top.rowItemFocused[0], 0]
        end if
    end if
    return handled
end function

function filterNodeArray(nodeArray as object, nodeKey as string, excludeArray as object) as object
    if excludeArray.IsEmpty() then return nodeArray

    newNodeArray = []
    for each node in nodeArray
        excludeThisNode = false
        for each exclude in excludeArray
            if node[nodeKey] = exclude
                excludeThisNode = true
            end if
        end for
        if excludeThisNode = false
            newNodeArray.Push(node)
        end if
    end for
    return newNodeArray
end function
