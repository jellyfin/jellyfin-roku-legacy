sub init()
    m.top.translation = [24,165]
    m.topGrp = m.top.findNode("personInfoGroup")
    m.vidsList = m.top.findNode("extrasGrid")
    m.personVideos = m.top.findnode("personVideos")
    m.loadPersonTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadPersonTask.itemsToLoad = "person"
    m.loadPersonTask.observeField("content", "onPersondataLoaded")
    ' set up to load image
    m.LoadImageUrlTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadImageUrlTask.itemsToLoad = "imageurl"
end sub

sub loadPerson(personId as string)
    m.personId = personId
    m.loadPersonTask.itemId = personId
    m.loadPersonTask.control = "RUN"
end sub

sub onPersondataLoaded()
    m.top.personData = m.loadPersonTask.content[0]
    m.loadPersonTask.unobserveField("content")
    data = m.top.personData
    m.top.findNode("Name").Text = data.Name
    if data.PremiereDate <> invalid and data.PremiereDate <> ""
        birthDate = CreateObject("roDateTime")
        birthDate.FromISO8601String(data.PremiereDate)
        deathDate = CreateObject("roDatetime")
        lifeString = "Born: " + birthDate.AsDateString("short-month-no-weekday")

        if data.EndDate <> invalid and data.EndDate <> ""
            deathDate.FromISO8601String(data.EndDate)
            lifeString = lifeString + " * Died: " + deathDate.AsDateString("short-month-no-weekday")

        end if
        ' Calculate age
        age = deathDate.getYear() - birthDate.getYear()
        if (deathDate.getMonth() < birthDate.getMonth())
            age--
        else if deathDate.getMonth() = birthDate.getMonth()
            if deathDate.getDayOfMonth() < birthDate.getDayOfMonth()
                age--
            end if
        end if
        lifeString = lifeString + " * Age: " + stri(age)
        m.top.findNode("premierDate").Text = lifeString
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
    m.vidsList .callFunc("loadPersonVideos", m.personId)
    m.topGrp.setFocus(true)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    'if not press then return false

    if key = "back" then
        m.global.sceneManager.callfunc("popScene")
        return true
    end if

    vs = m.top.findNode("VertSlider")
    bottomGrp = m.top.findNode("extrasGrid")

    if key = "down" and m.topGrp.isinFocusChain() then
        m.vidsList.setFocus(true)
        vs.reverse = false
        m.top.findNode("pplAnime").control = "start"
        return true
    else if key = "up" and m.vidsList.isinFocusChain()
        if m.vidsList.itemFocused = 0
            vs.reverse = true
            m.top.findNode("pplAnime").control = "start"
            m.topGrp.setFocus(true)
            return true
        end if
    end if
    return false
end function

function shortDate(isoDate) as string
    myDate = CreateObject("roDateTime")
    myDate.FromISO8601String(isoDate)
    return myDate.AsDateString("short-month-no-weekday")
end function
