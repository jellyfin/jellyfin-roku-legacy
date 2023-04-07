sub init()
    m.top.visible = true
    updateSize()
    m.top.rowFocusAnimationStyle = "fixedFocus"
    m.top.observeField("rowItemSelected", "onRowItemSelected")
    m.unsortedContent = CreateObject("roSGNode", "ContentNode")
    m.top.content = CreateObject("roSGNode", "ContentNode")
    m.rowitemSize = []
    m.loadingComplete = false

    ' Set up all Tasks
    m.LoadPeopleTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadPeopleTask.itemsToLoad = "people"
    m.LoadPeopleTask.observeField("content", "onPeopleLoaded")
    m.LikeThisTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LikeThisTask.itemsToLoad = "likethis"
    m.LikeThisTask.observeField("content", "onLikeThisLoaded")
    m.SpecialFeaturesTask = CreateObject("roSGNode", "LoadItemsTask")
    m.SpecialFeaturesTask.itemsToLoad = "specialfeatures"
    m.SpecialFeaturesTask.observeField("content", "onSpecialFeaturesLoaded")
    m.LoadAdditionalPartsTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadAdditionalPartsTask.itemsToLoad = "additionalparts"
    m.LoadAdditionalPartsTask.observeField("content", "onAdditionalPartsLoaded")
    m.LoadMoviesTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadMoviesTask.itemsToLoad = "personMovies"
    m.LoadShowsTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadShowsTask.itemsToLoad = "personTVShows"
    m.LoadSeriesTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadSeriesTask.itemsToLoad = "personSeries"
end sub

sub updateSize()
    itemHeight = 396
    m.top.itemSize = [1710, itemHeight]
    m.top.rowItemSpacing = [36, 36]
end sub

sub loadParts(data as object, playback = false)
    m.rowTitlesInOrder = [tr("Cast & Crew"), tr("Additional Parts"), tr("More Like This"), tr("Special Features")]
    m.rowSizes = [[234, 396], [464, 291], [234, 396], [462, 372]]
    m.tasksToComplete = m.rowTitlesInOrder.count()
    m.top.parentId = data.id
    m.people = data.People
    m.LoadPeopleTask.peopleList = m.people
    m.LoadPeopleTask.control = "RUN"
    if not playback
        m.LoadAdditionalPartsTask.itemId = m.top.parentId
        m.LoadAdditionalPartsTask.control = "RUN"
        m.LikeThisTask.itemId = m.top.parentId
        m.LikeThisTask.control = "RUN"
        m.SpecialFeaturesTask.itemId = m.top.parentId
        m.SpecialFeaturesTask.control = "RUN"
    end if
end sub

sub loadPersonVideos(personId)
    m.rowTitlesInOrder = [tr("Movies"), tr("TV Shows"), tr("Series")]
    m.rowSizes = [[234, 396], [502, 396], [234, 396]]
    m.tasksToComplete = m.rowTitlesInOrder.count()
    m.personId = personId

    m.LoadMoviesTask.itemId = m.personId
    m.LoadMoviesTask.observeField("content", "onMoviesLoaded")
    m.LoadMoviesTask.control = "RUN"

    m.LoadShowsTask.itemId = m.personId
    m.LoadShowsTask.observeField("content", "onShowsLoaded")
    m.LoadShowsTask.control = "RUN"

    m.LoadSeriesTask.itemId = m.personId
    m.LoadSeriesTask.observeField("content", "onSeriesLoaded")
    m.LoadSeriesTask.control = "RUN"
end sub

sub onAdditionalPartsLoaded()
    m.tasksToComplete--
    parts = m.LoadAdditionalPartsTask.content
    m.LoadAdditionalPartsTask.unobserveField("content")

    if parts <> invalid and parts.count() > 0
        row = buildRow(tr("Additional Parts"), parts, 464)
        m.unsortedContent.appendChild(row)
    end if
    sortCompletedTasks()
end sub

sub onPeopleLoaded()
    m.tasksToComplete--
    people = m.LoadPeopleTask.content
    m.loadPeopleTask.unobserveField("content")
    if people <> invalid and people.count() > 0
        row = m.unsortedContent.createChild("ContentNode")
        row.Title = tr("Cast & Crew")
        for each person in people
            if person.json.type = "Actor" and person.json.Role <> invalid and person.json.Role.ToStr().Trim() <> ""
                person.subTitle = "as " + person.json.Role
            else
                person.subTitle = person.json.Type
            end if
            person.Type = "Person"
            row.appendChild(person)
        end for
    end if
    sortCompletedTasks()
end sub

sub onLikeThisLoaded()
    m.tasksToComplete--
    data = m.LikeThisTask.content
    m.LikeThisTask.unobserveField("content")
    if data <> invalid and data.count() > 0
        row = m.unsortedContent.createChild("ContentNode")
        row.Title = tr("More Like This")
        for each item in data
            item.Id = item.json.Id
            item.labelText = item.json.Name
            if item.json.ProductionYear <> invalid
                item.subTitle = stri(item.json.ProductionYear)
            else if item.json.PremiereDate <> invalid
                premierYear = CreateObject("roDateTime")
                premierYear.FromISO8601String(item.json.PremiereDate)
                item.subTitle = stri(premierYear.GetYear())
            end if
            item.Type = item.json.Type
            row.appendChild(item)
        end for
    end if
    sortCompletedTasks()
end sub

sub onSpecialFeaturesLoaded()
    m.tasksToComplete--
    data = m.SpecialFeaturesTask.content
    m.SpecialFeaturesTask.unobserveField("content")
    if data <> invalid and data.count() > 0
        row = m.unsortedContent.createChild("ContentNode")
        row.Title = tr("Special Features")
        for each item in data
            m.top.visible = true
            item.Id = item.json.Id
            item.labelText = item.json.Name
            item.subTitle = ""
            item.Type = item.json.Type
            item.imageWidth = 450
            row.appendChild(item)
        end for
    end if
    sortCompletedTasks()
end sub

sub onMoviesLoaded()
    m.tasksToComplete--
    data = m.LoadMoviesTask.content
    m.LoadMoviesTask.unobserveField("content")
    if data <> invalid and data.count() > 0
        row = buildRow(tr("Movies"), data)
        m.unsortedContent.insertChild(row, 3)
    end if
    sortCompletedTasks()
end sub

sub onShowsLoaded()
    m.tasksToComplete--
    data = m.LoadShowsTask.content
    m.LoadShowsTask.unobserveField("content")
    if data <> invalid and data.count() > 0
        row = buildRow(tr("TV Shows"), data, 502)
        m.unsortedContent.insertChild(row, 2)
    end if
    sortCompletedTasks()
end sub

sub onSeriesLoaded()
    m.tasksToComplete--
    data = m.LoadSeriesTask.content
    m.LoadSeriesTask.unobserveField("content")
    if data <> invalid and data.count() > 0
        row = buildRow(tr("Series"), data)
        m.unsortedContent.insertChild(row, 1)
    end if
    sortCompletedTasks()
end sub

function buildRow(rowTitle as string, items, imgWdth = 0)
    row = CreateObject("roSGNode", "ContentNode")
    row.Title = tr(rowTitle)
    for each mov in items
        mov.Id = mov.json.Id
        mov.labelText = mov.json.Name
        mov.subTitle = mov.json.ProductionYear
        mov.Type = mov.json.Type
        if imgWdth > 0
            mov.imageWidth = imgWdth
        end if
        row.appendChild(mov)
    end for
    return row
end function

sub addRowSize(newRow)
    sizeArray = m.top.rowItemSize
    newSizeArray = []
    for each size in sizeArray
        newSizeArray.push(size)
    end for
    newSizeArray.push(newRow)
    m.top.rowItemSize = newSizeArray
end sub

sub onRowItemSelected()
    m.top.selectedItem = m.top.content.getChild(m.top.rowItemSelected[0]).getChild(m.top.rowItemSelected[1])
end sub

function getIndex(rowTitle, arr)
    rowIndex = invalid
    for i = 0 to arr.getChildCount() - 1
        tmpRow = m.unsortedContent.getChild(i)
        if tmpRow.title = rowTitle
            rowIndex = i
            return rowIndex
        end if
    end for
    return rowIndex
end function

sub sortCompletedTasks()
    ' if the next item we are waiting for has been loaded,
    ' process it and remove it from the items we are waiting for
    rowIndex = getIndex(m.rowTitlesInOrder[0], m.unsortedContent) ' the index of the next item we want, invalid if item has not been completed
    while m.unsortedContent.getChildCount() > 0 and rowIndex <> invalid
        child = m.unsortedContent.getChild(rowIndex)
        m.top.content.appendChild(child)
        m.unsortedContent.removeChild(child)
        addRowSize(m.rowSizes[0])
        m.rowSizes.shift()
        m.rowTitlesInOrder.shift()
        rowIndex = getIndex(m.rowTitlesInOrder[0], m.unsortedContent)
    end while
    if m.tasksToComplete = 0 and not m.loadingComplete
        'everything loaded, but the next item we waited for was invalid, so load what we have
        'this happens, for example, when there are no 'Additional Parts'
        for i = 0 to m.rowTitlesInOrder.count() - 1
            rowIndex = getIndex(m.rowTitlesInOrder[i], m.unsortedContent)
            if rowIndex <> invalid
                m.top.content.appendChild(m.unsortedContent.getChild(rowIndex))
                addRowSize(m.rowSizes[i])
            end if
        end for
        m.loadingComplete = true
    end if
end sub
