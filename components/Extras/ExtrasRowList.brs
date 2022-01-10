sub init()
    m.top.visible = true
    updateSize()
    m.top.observeField("rowItemSelected", "onRowItemSelected")
    m.LoadPeopleTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadPeopleTask.itemsToLoad = "people"
    m.LoadPeopleTask.observeField("content", "onPeopleLoaded")
end sub

sub updateSize()
    itemWidth = 240
    itemHeight = 360
    m.top.itemSize = [1710, itemHeight]
    m.top.rowItemSize = [itemWidth, itemHeight]
    m.top.rowItemSpacing = [24, 30]
end sub

sub loadPeople(data as object)
    m.LoadPeopleTask.peopleList = data.People
    m.LoadPeopleTask.control = "RUN"
end sub

function onPeopleLoaded()
    people = m.LoadPeopleTask.content
    m.loadPeopleTask.unobserveField("content")
    data = CreateObject("roSGNode", "ContentNode") ' The row Node
    row = data.createChild("ContentNode")
    row.Title = "Cast & Crew"
    for each person in people
        row.appendChild(person)
    end for

    ' Create a diummy row until other rows are defined
    row = data.CreateChild ("ContentNode")
    row.title = "Second Row"
    list = ["First One", "Second One"]
    for each item in list
        img = row.createChild("ExtrasData")
        img.labelText = item
        img.subTitle = "Sluggard"
        img.posterUrl = "pkg:/images/baseline_person_white_48dp.png"
    end for
    m.top.content = data
    m.top.visible = true
    return m.top.content
end function

function setData()
    people = m.LoadPeopleTask.content
    m.loadPeopleTask.unobserveField("content")
    data = CreateObject("roSGNode", "ContentNode") ' The row Node

    ' Create "Cast & Crew" Row
    row = data.createChild("ContentNode")
    row.Title = "Cast & Crew"
    for each person in people
        person.id = person.id
        person.labelText = person.name
        person.subTitle = person.Type
        row.appendChild(person)
    end for
    
    ' Create a diummy row until other rows are defined
    row = data.CreateChild ("ContentNode")
    row.title = "Second Row"
    list = ["First One", "Second One"]
    for each item in list
        img = row.createChild("ExtrasData")
        img.labelText = item
        img.subTitle = "Sluggard"
        img.posterUrl = "pkg:/images/baseline_person_white_48dp.png"
    end for
    return data
end function

sub onRowItemSelected()
    m.top.selectedExtra = m.top.content.getChild(m.top.rowItemSelected[0]).getChild(m.top.rowItemSelected[1])
end sub
