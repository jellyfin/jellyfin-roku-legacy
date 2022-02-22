sub init()
    m.topGrp = m.top.findNode("description")
    m.topGrp.translation = [24, 165]
    m.top.optionsAvailable = false
    m.vidsList = m.top.findNode("extrasGrid")
    m.showVidTxt = m.top.findNode("showVidText")
end sub

sub loadPerson()
    data = m.top.json
    m.top.findNode("Name").Text = data.Name
    if data.PremiereDate <> invalid and data.PremiereDate <> ""
        birthDate = CreateObject("roDateTime")
        birthDate.FromISO8601String(data.PremiereDate)
        deathDate = CreateObject("roDatetime")
        lifeString = tr("Born") + ": " + birthDate.AsDateString("short-month-no-weekday")

        if data.EndDate <> invalid and data.EndDate <> ""
            deathDate.FromISO8601String(data.EndDate)
            lifeString = lifeString + " * " + tr("Died") + ": " + deathDate.AsDateString("short-month-no-weekday")

        end if
        ' Calculate age
        age = deathDate.getYear() - birthDate.getYear()
        if deathDate.getMonth() < birthDate.getMonth()
            age--
        else if deathDate.getMonth() = birthDate.getMonth()
            if deathDate.getDayOfMonth() < birthDate.getDayOfMonth()
                age--
            end if
        end if
        lifeString = lifeString + " * " + tr("Age") + ": " + stri(age)
        m.top.findNode("premierDate").Text = lifeString
    end if
    m.top.findnode("description").text = data.Overview
    if m.top.image <> invalid
        m.top.findnode("personImage").uri = m.top.image.url
    else
        m.top.findnode("personImage").uri = "pkg:/images/baseline_person_white_48dp.png"
    end if
    m.vidsList .callFunc("loadPersonVideos", m.top.json.Id)
    m.topGrp.setFocus(true)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "back"
        m.global.sceneManager.callfunc("popScene")
        return true
    end if

    if key = "options"
        if m.showVidTxt.text = "Show Videos"
            m.vidsList.setFocus(true)
            m.top.findNode("VertSlider").reverse = false
            m.top.findNode("extrasFader").reverse = false
            m.top.findNode("pplAnime").control = "start"
            m.showVidTxt.text = "Hide Videos"
            return true
        else
            m.top.findNode("VertSlider").reverse = true
            m.top.findNode("extrasFader").reverse = true
            m.top.findNode("pplAnime").control = "start"
            m.topGrp.setFocus(true)
            m.showVidTxt.text = "Show Videos"
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
