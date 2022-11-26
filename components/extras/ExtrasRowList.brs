sub init()
    m.top.visible = true
    updateSize()
    m.top.rowFocusAnimationStyle = "fixedFocus"
    m.top.observeField("rowItemSelected", "onRowItemSelected")

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

sub loadPeople(data as object)
    m.top.parentId = data.id
    m.LoadPeopleTask.peopleList = data.People
    m.LoadPeopleTask.control = "RUN"
end sub

sub loadPersonVideos(personId)
    m.personId = personId
    m.LoadMoviesTask.itemId = m.personId
    m.LoadMoviesTask.observeField("content", "onMoviesLoaded")
    m.LoadMoviesTask.control = "RUN"
end sub

sub onPeopleLoaded()
    people = m.LoadPeopleTask.content
    m.loadPeopleTask.unobserveField("content")
    data = CreateObject("roSGNode", "ContentNode") ' The row Node
    if people <> invalid and people.count() > 0
        row = data.createChild("ContentNode")
        row.Title = tr("Cast & Crew")
        for each person in people
            if person.json.type = "Actor" and person.json.Role <> invalid
                person.subTitle = "as " + person.json.Role
            else
                person.subTitle = person.json.Type
            end if
            person.Type = "Person"
            row.appendChild(person)
        end for
    end if
    m.top.content = data
    m.top.translation = "[75,10]"
    m.top.rowItemSize = [[234, 396]]
    m.LikeThisTask.itemId = m.top.parentId
    m.LikeThisTask.control = "RUN"
end sub

sub onLikeThisLoaded()
    data = m.LikeThisTask.content
    m.LikeThisTask.unobserveField("content")
    if data <> invalid and data.count() > 0
        row = m.top.content.createChild("ContentNode")
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
        addRowSize([234, 396])
    end if
    m.SpecialFeaturesTask.itemId = m.top.parentId
    m.SpecialFeaturesTask.control = "RUN"
end sub

function onSpecialFeaturesLoaded()
    data = m.SpecialFeaturesTask.content
    m.SpecialFeaturesTask.unobserveField("content")
    if data <> invalid and data.count() > 0
        row = m.top.content.createChild("ContentNode")
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
        addRowSize([462, 372])
    end if

    return m.top.content
end function

sub onMoviesLoaded()
    data = m.LoadMoviesTask.content
    m.LoadMoviesTask.unobserveField("content")
    rlContent = CreateObject("roSGNode", "ContentNode")
    if data <> invalid and data.count() > 0
        row = rlContent.createChild("ContentNode")
        row.title = tr("Movies")
        for each mov in data
            mov.Id = mov.json.Id
            mov.labelText = mov.json.Name
            mov.subTitle = mov.json.ProductionYear
            mov.Type = mov.json.Type
            row.appendChild(mov)
        end for
        m.top.rowItemSize = [[234, 396]]
    end if
    m.top.content = rlContent
    m.LoadShowsTask.itemId = m.personId
    m.LoadShowsTask.observeField("content", "onShowsLoaded")
    m.LoadShowsTask.control = "RUN"
end sub

sub onShowsLoaded()
    data = m.LoadShowsTask.content
    m.LoadShowsTask.unobserveField("content")
    if data <> invalid and data.count() > 0
        row = buildRow("TV Shows", data, 502)
        addRowSize([502, 396])
        m.top.content.appendChild(row)
    end if
    m.LoadSeriesTask.itemId = m.personId
    m.LoadSeriesTask.observeField("content", "onSeriesLoaded")
    m.LoadSeriesTask.control = "RUN"
end sub

sub onSeriesLoaded()
    data = m.LoadSeriesTask.content
    m.LoadSeriesTask.unobserveField("content")
    if data <> invalid and data.count() > 0
        row = buildRow("Series", data)
        addRowSize([234, 396])
        m.top.content.appendChild(row)
    end if
    m.top.visible = true
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
