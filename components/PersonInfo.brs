sub init()
    m.top.translation = [24,165]
    m.loadPersonTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadPersonTask.itemsToLoad = "person"
    m.loadPersonTask.observeField("content", "onPersondataLoaded")
    ' set up to load imae
    m.LoadImageUrlTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadImageUrlTask.itemsToLoad = "imageurl"
end sub

sub loadPerson(personId as string)
    m.loadPersonTask.itemId = personId
    m.loadPersonTask.control = "RUN"
end sub

sub onPersondataLoaded()
    m.top.personData = m.loadPersonTask.content[0]
    m.loadPersonTask.unobserveField("content")
    data = m.top.personData
    m.top.findNode("Name").Text = data.Name
    if data.PremiereDate = invalid then
        m.top.findnode("premierDate").PremiereDate.Text = "???"
    else
        m.top.findNode("premierDate").Text = "Born: " + shortDate(data.PremiereDate)
    end if
    endDate = m.top.findnode("endDate")
    if data.endDate <> invalid and data.EndDate <> ""
        endDate.height = 60
        endDate.Text = "Died: " + shortDate(data.endDate)
    end if
    m.top.findnode("description").text = data.Overview
    if data.ImageTags.Primary <> invalid
        m.LoadImageUrlTask.itemId = data.Id
        m.LoadImageUrlTask.metadata = { "Tags": data.ImageTags.Primary }
        m.LoadImageUrlTask.observeField("content", "onImageUrlLoaded")
        m.LoadImageUrlTask.control = "RUN"
    else
        m.top.findnode("personImage").uri = "pkg:/images/baseline_person_white_48dp.png"
    end if
end sub

sub onImageUrlLoaded()
    data = m.LoadImageUrlTask.content[0]
    m.LoadImageUrlTask.unobserveField("content")
    m.top.findnode("personImage").uri = data
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    'if not press then return false

    if key = "back" then
        m.global.sceneManager.callfunc("popScene")
        return true
    end if

    return false
end function

function shortDate(isoDate) as string
    myDate = CreateObject("roDateTime")
    myDate.FromISO8601String(isoDate)
    return myDate.AsDateString("short-month-no-weekday")
end function
