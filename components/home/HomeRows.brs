sub init()
    m.top.itemComponentName = "HomeItem"
    ' how many rows are visible on the screen
    m.top.numRows = 2

    m.top.rowFocusAnimationStyle = "fixedFocusWrap"
    m.top.vertFocusAnimationStyle = "fixedFocus"

    m.top.showRowLabel = [true]
    m.top.rowLabelOffset = [0, 20]
    m.top.showRowCounter = [true]

    m.top.latestMediaCount = 0
    m.top.latestMediaInt = 0
    m.top.latestMediaNode = ""
    m.top.nodeCount = 0
    m.top.sectionCount = 0

    updateSize()

    m.top.setfocus(true)

    m.top.observeField("rowItemSelected", "itemSelected")

    ' Load the Libraries from API via task
    m.LoadLibrariesTask = createObject("roSGNode", "LoadItemsTask")
    m.LoadLibrariesTask.observeField("content", "onLibrariesLoaded")

    m.LoadHomeSectionTask = createObject("roSGNode", "LoadItemsTask")

    m.LoadMyMediaTask = createObject("roSGNode", "LoadItemsTask")
    m.LoadMyMediaSmallTask = createObject("roSGNode", "LoadItemsTask")
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
    itemHeight = 330

    'Set width of Rows to cut off at edge of Safe Zone
    m.top.itemSize = [1703, itemHeight]

    ' spacing between rows
    m.top.itemSpacing = [0, 105]

    ' spacing between items in a row
    m.top.rowItemSpacing = [20, 0]

    m.top.visible = true
end sub

sub onLibrariesLoaded()
    m.LoadHomeSectionTask.observeField("content", "loadHomeSection0")
    m.LoadHomeSectionTask.control = "RUN"
end sub

sub loadHomeSection0()
    m.libraryData = m.LoadLibrariesTask.content
    m.LoadLibrariesTask.unobserveField("content")
    content = CreateObject("roSGNode", "ContentNode")
    m.top.content = content

    createHoldingChildren()

    m.top.latestMediaInt = getHomeSectionInt("latestmedia")
    m.top.sectionCount = getHomeSectionCount()

    homesection0 = get_user_setting("display.homesection0")

    if homesection0 = "smalllibrarytiles"
        m.LoadMyMediaTask.observeField("content", "updateMyMedia")
        m.LoadMyMediaTask.control = "RUN"
    else if homesection0 = "librarybuttons"
        m.LoadMyMediaSmallTask.observeField("content", "updateMyMediaSmall")
        m.LoadMyMediaSmallTask.control = "RUN"
    else if homesection0 = "latestmedia"
        m.LoadLatestMediaTask.observeField("content", "updateLatestMedia")
        m.LoadLatestMediaTask.control = "RUN"
    else if homesection0 = "resume"
        m.LoadContinueVideoTask.observeField("content", "updateContinueVideoItems")
        m.LoadContinueVideoTask.control = "RUN"
    else if homesection0 = "resumeaudio"
        m.LoadContinueAudioTask.observeField("content", "updateContinueAudioItems")
        m.LoadContinueAudioTask.control = "RUN"
    else if homesection0 = "resumebook"
        m.LoadContinueBookTask.observeField("content", "updateContinueBookItems")
        m.LoadContinueBookTask.control = "RUN"
    else if homesection0 = "nextup"
        m.LoadNextUpTask.observeField("content", "updateNextUpItems")
        m.LoadNextUpTask.control = "RUN"
    else if homesection0 = "livetv"
        m.LoadOnNowTask.observeField("content", "updateOnNowItems")
        m.LoadOnNowTask.control = "RUN"
    else
        removeHoldingChild(1)
    end if
    m.top.content = content
    loadHomeSection1()
end sub

sub loadHomeSection1()
    content = m.top.content

    homesection1 = get_user_setting("display.homesection1")

    if homesection1 = "smalllibrarytiles"
        m.LoadMyMediaTask.observeField("content", "updateMyMedia")
        m.LoadMyMediaTask.control = "RUN"
    else if homesection1 = "librarybuttons"
        m.LoadMyMediaSmallTask.observeField("content", "updateMyMediaSmall")
        m.LoadMyMediaSmallTask.control = "RUN"
    else if homesection1 = "latestmedia"
        m.LoadLatestMediaTask.observeField("content", "updateLatestMedia")
        m.LoadLatestMediaTask.control = "RUN"
    else if homesection1 = "resume"
        m.LoadContinueVideoTask.observeField("content", "updateContinueVideoItems")
        m.LoadContinueVideoTask.control = "RUN"
    else if homesection1 = "resumeaudio"
        m.LoadContinueAudioTask.observeField("content", "updateContinueAudioItems")
        m.LoadContinueAudioTask.control = "RUN"
    else if homesection1 = "resumebook"
        m.LoadContinueBookTask.observeField("content", "updateContinueBookItems")
        m.LoadContinueBookTask.control = "RUN"
    else if homesection1 = "nextup"
        m.LoadNextUpTask.observeField("content", "updateNextUpItems")
        m.LoadNextUpTask.control = "RUN"
    else if homesection1 = "livetv"
        m.LoadOnNowTask.observeField("content", "updateOnNowItems")
        m.LoadOnNowTask.control = "RUN"
    else
        removeHoldingChild(2)
    end if
    m.top.content = content
    loadHomeSection2()
end sub

sub loadHomeSection2()
    content = m.top.content

    homesection2 = get_user_setting("display.homesection2")

    if homesection2 = "smalllibrarytiles"
        m.LoadMyMediaTask.observeField("content", "updateMyMedia")
        m.LoadMyMediaTask.control = "RUN"
    else if homesection2 = "librarybuttons"
        m.LoadMyMediaSmallTask.observeField("content", "updateMyMediaSmall")
        m.LoadMyMediaSmallTask.control = "RUN"
    else if homesection2 = "latestmedia"
        m.LoadLatestMediaTask.observeField("content", "updateLatestMedia")
        m.LoadLatestMediaTask.control = "RUN"
    else if homesection2 = "resume"
        m.LoadContinueVideoTask.observeField("content", "updateContinueVideoItems")
        m.LoadContinueVideoTask.control = "RUN"
    else if homesection2 = "resumeaudio"
        m.LoadContinueAudioTask.observeField("content", "updateContinueAudioItems")
        m.LoadContinueAudioTask.control = "RUN"
    else if homesection2 = "resumebook"
        m.LoadContinueBookTask.observeField("content", "updateContinueBookItems")
        m.LoadContinueBookTask.control = "RUN"
    else if homesection2 = "nextup"
        m.LoadNextUpTask.observeField("content", "updateNextUpItems")
        m.LoadNextUpTask.control = "RUN"
    else if homesection2 = "livetv"
        m.LoadOnNowTask.observeField("content", "updateOnNowItems")
        m.LoadOnNowTask.control = "RUN"
    else
        removeHoldingChild(3)
    end if
    m.top.content = content
    loadHomeSection3()
end sub

sub loadHomeSection3()
    content = m.top.content

    homesection3 = get_user_setting("display.homesection3")

    if homesection3 = "smalllibrarytiles"
        m.LoadMyMediaTask.observeField("content", "updateMyMedia")
        m.LoadMyMediaTask.control = "RUN"
    else if homesection3 = "librarybuttons"
        m.LoadMyMediaSmallTask.observeField("content", "updateMyMediaSmall")
        m.LoadMyMediaSmallTask.control = "RUN"
    else if homesection3 = "latestmedia"
        m.LoadLatestMediaTask.observeField("content", "updateLatestMedia")
        m.LoadLatestMediaTask.control = "RUN"
    else if homesection3 = "resume"
        m.LoadContinueVideoTask.observeField("content", "updateContinueVideoItems")
        m.LoadContinueVideoTask.control = "RUN"
    else if homesection3 = "resumeaudio"
        m.LoadContinueAudioTask.observeField("content", "updateContinueAudioItems")
        m.LoadContinueAudioTask.control = "RUN"
    else if homesection3 = "resumebook"
        m.LoadContinueBookTask.observeField("content", "updateContinueBookItems")
        m.LoadContinueBookTask.control = "RUN"
    else if homesection3 = "nextup"
        m.LoadNextUpTask.observeField("content", "updateNextUpItems")
        m.LoadNextUpTask.control = "RUN"
    else if homesection3 = "livetv"
        m.LoadOnNowTask.observeField("content", "updateOnNowItems")
        m.LoadOnNowTask.control = "RUN"
    else
        removeHoldingChild(4)
    end if
    m.top.content = content
    loadHomeSection4()
end sub

sub loadHomeSection4()
    content = m.top.content

    homesection4 = get_user_setting("display.homesection4")

    if homesection4 = "smalllibrarytiles"
        m.LoadMyMediaTask.observeField("content", "updateMyMedia")
        m.LoadMyMediaTask.control = "RUN"
    else if homesection4 = "librarybuttons"
        m.LoadMyMediaSmallTask.observeField("content", "updateMyMediaSmall")
        m.LoadMyMediaSmallTask.control = "RUN"
    else if homesection4 = "latestmedia"
        m.LoadLatestMediaTask.observeField("content", "updateLatestMedia")
        m.LoadLatestMediaTask.control = "RUN"
    else if homesection4 = "resume"
        m.LoadContinueVideoTask.observeField("content", "updateContinueVideoItems")
        m.LoadContinueVideoTask.control = "RUN"
    else if homesection4 = "resumeaudio"
        m.LoadContinueAudioTask.observeField("content", "updateContinueAudioItems")
        m.LoadContinueAudioTask.control = "RUN"
    else if homesection4 = "resumebook"
        m.LoadContinueBookTask.observeField("content", "updateContinueBookItems")
        m.LoadContinueBookTask.control = "RUN"
    else if homesection4 = "nextup"
        m.LoadNextUpTask.observeField("content", "updateNextUpItems")
        m.LoadNextUpTask.control = "RUN"
    else if homesection4 = "livetv"
        m.LoadOnNowTask.observeField("content", "updateOnNowItems")
        m.LoadOnNowTask.control = "RUN"
    else
        removeHoldingChild(5)
    end if
    m.top.content = content
    loadHomeSection5()
end sub

sub loadHomeSection5()
    content = m.top.content

    homesection5 = get_user_setting("display.homesection5")

    if homesection5 = "smalllibrarytiles"
        m.LoadMyMediaTask.observeField("content", "updateMyMedia")
        m.LoadMyMediaTask.control = "RUN"
    else if homesection5 = "librarybuttons"
        m.LoadMyMediaSmallTask.observeField("content", "updateMyMediaSmall")
        m.LoadMyMediaSmallTask.control = "RUN"
    else if homesection5 = "latestmedia"
        m.LoadLatestMediaTask.observeField("content", "updateLatestMedia")
        m.LoadLatestMediaTask.control = "RUN"
    else if homesection5 = "resume"
        m.LoadContinueVideoTask.observeField("content", "updateContinueVideoItems")
        m.LoadContinueVideoTask.control = "RUN"
    else if homesection5 = "resumeaudio"
        m.LoadContinueAudioTask.observeField("content", "updateContinueAudioItems")
        m.LoadContinueAudioTask.control = "RUN"
    else if homesection5 = "resumebook"
        m.LoadContinueBookTask.observeField("content", "updateContinueBookItems")
        m.LoadContinueBookTask.control = "RUN"
    else if homesection5 = "nextup"
        m.LoadNextUpTask.observeField("content", "updateNextUpItems")
        m.LoadNextUpTask.control = "RUN"
    else if homesection5 = "livetv"
        m.LoadOnNowTask.observeField("content", "updateOnNowItems")
        m.LoadOnNowTask.control = "RUN"
    else
        removeHoldingChild(6)
    end if

    m.top.content = content
    loadHomeSection6()
end sub

sub loadHomeSection6()
    content = m.top.content

    homesection6 = get_user_setting("display.homesection6")

    if homesection6 = "smalllibrarytiles"
        m.LoadMyMediaTask.observeField("content", "updateMyMedia")
        m.LoadMyMediaTask.control = "RUN"
    else if homesection6 = "librarybuttons"
        m.LoadMyMediaSmallTask.observeField("content", "updateMyMediaSmall")
        m.LoadMyMediaSmallTask.control = "RUN"
    else if homesection6 = "latestmedia"
        m.LoadLatestMediaTask.observeField("content", "updateLatestMedia")
        m.LoadLatestMediaTask.control = "RUN"
    else if homesection6 = "resume"
        m.LoadContinueVideoTask.observeField("content", "updateContinueVideoItems")
        m.LoadContinueVideoTask.control = "RUN"
    else if homesection6 = "resumeaudio"
        m.LoadContinueAudioTask.observeField("content", "updateContinueAudioItems")
        m.LoadContinueAudioTask.control = "RUN"
    else if homesection6 = "resumebook"
        m.LoadContinueBookTask.observeField("content", "updateContinueBookItems")
        m.LoadContinueBookTask.control = "RUN"
    else if homesection6 = "nextup"
        m.LoadNextUpTask.observeField("content", "updateNextUpItems")
        m.LoadNextUpTask.control = "RUN"
    else if homesection6 = "livetv"
        m.LoadOnNowTask.observeField("content", "updateOnNowItems")
        m.LoadOnNowTask.control = "RUN"
    end if

    m.top.content = content

    ' consider home screen loaded when above rows are loaded
    if m.global.app_loaded = false
        m.top.signalBeacon("AppLaunchComplete") ' Roku Performance monitoring
        m.global.app_loaded = true
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
    row = content.getChild(row_index)
    content.removeChild(row)
    m.top.content = content
end sub

sub removeHoldingChildren()
    home_section_count = getHomeSectionCount()
    content = m.top.content
    for i = 1 to home_section_count
        row_index = getRowIndex(Substitute("Loading Section {0}...", child.toStr()))
        row = content.getChild(row_index)
        content.removeChild(row)
    end for
    m.top.content = content
end sub

sub rebuildItemArray()
    section_count = getHomeSectionCount()

    m.top.rowItemSize = []

    for i = 0 to section_count
        homesection = get_user_setting(Substitute("display.homesection{0}", i.toStr()))
        if homesection = "latestmedia"
            userConfig = m.top.userConfig
            filteredLatest = filterNodeArray(m.libraryData, "id", userConfig.LatestItemsExcludes)
            for each lib in filteredLatest
                if lib.collectionType <> "boxsets" and lib.collectionType <> "livetv"
                    itemSize = [200, 331]
                    updateSizeArray(itemSize)
                end if
            end for
        end if
        if homesection <> "latestmedia" and homesection <> "none"
            itemSize = [464, 261]
            if homesection = "librarybuttons"
                itemSize = [464, 100]
            else if homesection = "resumebook"
                itemSize = [200, 331]
            end if
            updateSizeArray(itemSize)
        end if
    end for
end sub

sub updateHomeRows()
    m.LoadContinueVideoTask.observeField("content", "loadHomeSection0")
    m.LoadContinueVideoTask.control = "RUN"
end sub

function getHomeSectionInt(section as string)
    home_section_count = getHomeSectionCount()
    for i = 0 to home_section_count
        homesection = get_user_setting(Substitute("display.homesection{0}", i.toStr()))
        if homesection = section
            return i
        end if
    end for
    return -1
end function

function getHomeSectionCount()
    section_count = 0
    for i = 0 to 6
        homesection = get_user_setting(Substitute("display.homesection{0}", i.toStr()))
        if homesection = "latestmedia"
            userConfig = m.top.userConfig
            filteredLatest = filterNodeArray(m.libraryData, "id", userConfig.LatestItemsExcludes)
            for each lib in filteredLatest
                if lib.collectionType <> "boxsets" and lib.collectionType <> "livetv"
                    section_count += 1
                end if
            end for
        end if
        if homesection <> "latestmedia" and homesection <> "none"
            section_count += 1
        end if
    end for
    return section_count
end function

sub updateMyMedia()
    homeRows = m.top.content
    section = getHomeSectionInt("smalllibrarytiles")
    m.LoadMyMediaTask.control = "RUN"
    itemData = m.LoadMyMediaTask.content
    m.LoadMyMediaTask.unobserveField("content")
    m.LoadMyMediaTask.content = []

    itemSize = [464, 261]

    latest_media_int = m.top.latestMediaInt
    latestMediaCount = m.top.latestMediaCount - 1
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

    section_count = m.top.sectionCount
    if section_count = section + latestMediaCount
        rebuildItemArray()
    end if
end sub

sub updateMyMediaSmall()
    homeRows = m.top.content
    section = getHomeSectionInt("librarybuttons")
    itemData = m.LoadMyMediaSmallTask.content
    m.LoadMyMediaSmallTask.unobserveField("content")
    m.LoadMyMediaSmallTask.content = []

    itemSize = [464, 100]

    latest_media_int = m.top.latestMediaInt
    latestMediaCount = m.top.latestMediaCount - 1
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

    section_count = m.top.sectionCount
    if section_count = section + latestMediaCount
        rebuildItemArray()
    end if
end sub

sub updateLatestMedia()
    userConfig = m.top.userConfig
    filteredLatest = filterNodeArray(m.libraryData, "id", userConfig.LatestItemsExcludes)
    latest_count = 0
    for each lib in filteredLatest
        if lib.collectionType <> "boxsets" and lib.collectionType <> "livetv"
            latest_count = latest_count + 1
            loadLatest = createObject("roSGNode", "LoadItemsTask")
            loadLatest.itemsToLoad = "latest"
            loadLatest.itemId = lib.id

            metadata = { "title": lib.name }
            metadata.Append({ "contentType": lib.json.CollectionType })
            loadLatest.metadata = metadata

            loadLatest.observeField("content", "updateLatestItems")
            loadLatest.control = "RUN"
        end if
    end for
    m.top.latestMediaCount = latest_count
end sub

sub updateContinueVideoItems()
    homeRows = m.top.content
    section = getHomeSectionInt("resume")
    itemData = m.LoadContinueVideoTask.content
    m.LoadContinueVideoTask.unobserveField("content")
    m.LoadContinueVideoTask.content = []

    itemSize = [464, 331]

    latest_media_int = m.top.latestMediaInt
    latestMediaCount = m.top.latestMediaCount - 1
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

    section_count = m.top.sectionCount
    if section_count = section + latestMediaCount
        rebuildItemArray()
    end if
end sub

sub updateContinueAudioItems()
    homeRows = m.top.content
    section = getHomeSectionInt("resumeaudio")
    itemData = m.LoadContinueAudioTask.content
    m.LoadContinueAudioTask.unobserveField("content")
    m.LoadContinueAudioTask.content = []

    itemSize = [464, 331]

    latest_media_int = m.top.latestMediaInt
    latestMediaCount = m.top.latestMediaCount - 1
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

    section_count = m.top.sectionCount
    if section_count = section + latestMediaCount
        rebuildItemArray()
    end if
end sub

sub updateContinueBookItems()
    homeRows = m.top.content
    section = getHomeSectionInt("resumebook")
    itemData = m.LoadContinueBookTask.content
    m.LoadContinueBookTask.unobserveField("content")
    m.LoadContinueBookTask.content = []

    itemSize = [200, 331]

    latest_media_int = m.top.latestMediaInt
    latestMediaCount = m.top.latestMediaCount - 1
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

    section_count = m.top.sectionCount
    if section_count = section + latestMediaCount
        rebuildItemArray()
    end if
end sub

sub updateNextUpItems()
    itemData = m.LoadNextUpTask.content
    m.LoadNextUpTask.unobserveField("content")
    m.LoadNextUpTask.content = []

    itemSize = [464, 331]

    homeRows = m.top.content
    section = getHomeSectionInt("nextup")

    latest_media_int = m.top.latestMediaInt
    latestMediaCount = m.top.latestMediaCount - 1
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

    section_count = m.top.sectionCount
    if section_count = section + latestMediaCount
        rebuildItemArray()
    end if
end sub

sub updateLatestItems(msg)
    itemData = msg.GetData()

    node = msg.getRoSGNode()
    node.unobserveField("content")
    node.content = []

    homeRows = m.top.content
    section = getHomeSectionInt("latestmedia")
    latest_node = m.top.latestMediaNode
    node_count = m.top.nodeCount
    section_count = m.top.sectionCount
    latest_media_int = m.top.latestMediaInt
    latestMediaCount = m.top.latestMediaCount - 1

    if latest_node = ""
        m.top.latestMediaNode = node.metadata.title
    end if

    if latest_node <> "" and latest_node <> node.metadata.title
        node_count++
        m.top.nodeCount = node_count
        m.top.latestMediaNode = node.metadata.title
    end if
    
    latest_count = 0
    index_section = section + 1
    index_section_latest = index_section + node_count
    row_index = getRowIndex(Substitute("Loading Section {0}...", index_section_latest.toStr()))
    if row_index <> invalid
        row = homeRows.getChild(row_index)
        item_count = itemData.count()
        if item_count > 1000
            item_count = 1000
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

    if section_count = index_section + node_count
        rebuildItemArray()
    end if
end sub

sub updateOnNowItems()
    itemData = m.LoadOnNowTask.content
    m.LoadOnNowTask.unobserveField("content")
    m.LoadOnNowTask.content = []

    itemSize = [464, 331]

    homeRows = m.top.content
    section = getHomeSectionInt("livetv")

    latest_media_int = m.top.latestMediaInt
    latestMediaCount = m.top.latestMediaCount - 1
    if latest_media_int < section
        if latestMediaCount > 0
            section = section + latestMediaCount
        end if
    end if

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
                itemData[i].usePoster = false
                itemData[i].imageWidth = 464
                row.appendChild(itemData[i])
            end if
        end for
        updateSizeArray(itemSize, section + latestMediaCount, "replace")
        row.update(row, false)
    end if

    section_count = m.top.sectionCount
    if section_count = section + latestMediaCount
        rebuildItemArray()
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