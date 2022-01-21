sub init()
    m.top.visible = true
    updateSize()
    m.top.rowFocusAnimationStyle = "fixedFocus"
    m.top.observeField("rowItemSelected", "onRowItemSelected")
    m.LoadPeopleTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadPeopleTask.itemsToLoad = "people"
    m.LoadPeopleTask.observeField("content", "onPeopleLoaded")
    m.LikeThisTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LikeThisTask.itemsToLoad = "likethis"
    m.LikeThisTask.observeField("content", "onLikeThisLoaded")
end sub

sub updateSize()
    itemWidth = 234
    itemHeight = 420
    m.top.itemSize = [1710, itemHeight]
    m.top.rowItemSize = [itemWidth, itemHeight]
    m.top.rowItemSpacing = [36, 36]
end sub

sub loadPeople(data as object)
    m.top.parentId = data.id
    m.LoadPeopleTask.peopleList = data.People
    m.LoadPeopleTask.control = "RUN"
end sub

function onPeopleLoaded()
    people = m.LoadPeopleTask.content
    m.loadPeopleTask.unobserveField("content")
    data = CreateObject("roSGNode", "ContentNode") ' The row Node
    if people <> invalid and people.count() > 0
        row = data.createChild("ContentNode")
        row.Title = "Cast & Crew"
        for each person in people
            if person.json.type = "Actor"
                person.subTitle = "as " + person.json.Role
            else
                person.subTitle = person.json.Type
            end if
            person.Type = "Person"
            row.appendChild(person)
        end for
    end if
    m.top.content = data
    m.LikeThisTask.itemId = m.top.parentId
    m.LikeThisTask.control="RUN"
end function

function onLikeThisLoaded()
    data = m.LikeThisTask.content
    m.LikeThisTask.unobserveField("content")
    if data <> invalid and data.count() > 0
        row = m.top.content.createChild("ContentNode")
        row.Title = "More Like This"
        for each item in data
            item.Id = item.json.Id
            item.labelText = item.json.Name
            premierYear = CreateObject("roDateTime")
            premierYear.FromISO8601String(item.json.PremiereDate)
            item.subTitle = stri(premierYear.GetYear())
            row.appendChild(item)
            item.Type = item.json.Type
        end for
    end if
    m.top.visible = true
    return m.top.content
end function

sub onRowItemSelected()
    'm.top.selectedExtra = m.top.content.getChild(m.top.rowItemSelected[0]).getChild(m.top.rowItemSelected[1])
    m.top.selectedItem = m.top.content.getChild(m.top.rowItemSelected[0]).getChild(m.top.rowItemSelected[1])
end sub
