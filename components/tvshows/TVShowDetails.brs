sub init()
    m.top.optionsAvailable = false
    main = m.top.findNode("toplevel")
    main.translation = [96, 175]
    m.extrasSlider = m.top.findNode("tvSeasonExtras")
    'm.extrasSlider.translation = [30,1014]
    m.extrasSlider.visible = true
end sub

sub itemContentChanged()
    ' Updates video metadata
    ' TODO - make things use item rather than itemData
    item = m.top.itemContent
    itemData = item.json

    m.top.findNode("tvshowPoster").uri = m.top.itemContent.posterURL

    ' Handle all "As Is" fields
    m.top.overhangTitle = itemData.name

    'Check production year, if invalid remove label
    if itemData.productionYear <> invalid
        setFieldText("releaseYear", itemData.productionYear)
    else
        m.top.findNode("main_group").removeChild(m.top.findNode("releaseYear"))
    end if

    'Check officialRating, if invalid remove label
    if itemData.officialRating <> invalid
        setFieldText("officialRating", itemData.officialRating)
    else
        m.top.findNode("main_group").removeChild(m.top.findNode("officialRating"))
    end if

    'Check communityRating, if invalid remove label
    if itemData.communityRating <> invalid
        m.top.findNode("star").visible = true
        setFieldText("communityRating", int(itemData.communityRating * 10) / 10)
    else
        m.top.findNode("main_group").removeChild(m.top.findNode("communityRating"))
        m.top.findNode("main_group").removeChild(m.top.findNode("star"))
        m.top.findNode("star").visible = false
    end if

    setFieldText("overview", itemData.overview)


    if type(itemData.RunTimeTicks) = "LongInteger"
        setFieldText("runtime", stri(getRuntime()) + " mins")
    end if

    'History feild is set via the function getHistory()
    setFieldText("history", getHistory())

    'Check genres, if invalid remove label
    if itemData.genres.count() > 0
        setFieldText("genres", itemData.genres.join(", "))
    else
        m.top.findNode("main_group").removeChild(m.top.findNode("genres"))
    end if

    'We don't display Directors in the show page. Might want to remove this.
    for each person in itemData.people
        if person.type = "Director"
            exit for
        end if
    end for
    if itemData.taglines.count() > 0
        setFieldText("tagline", itemData.taglines[0])
    else
        m.top.findNode("main_group").removeChild(m.top.findNode("tagline"))
    end if
end sub

sub setFieldText(field, value)
    node = m.top.findNode(field)
    if node = invalid or value = invalid then return

    ' Handle non strings... Which _shouldn't_ happen, but hey
    if type(value) = "roInt" or type(value) = "Integer"
        value = str(value).trim()
    else if type(value) = "roFloat" or type(value) = "Float"
        value = str(value).trim()
    else if type(value) <> "roString" and type(value) <> "String"
        value = ""
    end if

    node.text = value
end sub

function getRuntime() as integer
    itemData = m.top.itemContent.json

    ' A tick is .1ms, so 1/10,000,000 for ticks to seconds,
    ' then 1/60 for seconds to minutess... 1/600,000,000
    return round(itemData.RunTimeTicks / 600000000.0)
end function

function getEndTime() as string
    itemData = m.top.itemContent.json

    date = CreateObject("roDateTime")
    duration_s = int(itemData.RunTimeTicks / 10000000.0)
    date.fromSeconds(date.asSeconds() + duration_s)
    date.toLocalTime()

    return formatTime(date)
end function

function getHistory() as string
    itemData = m.top.itemContent.json
    ' Aired Fridays at 9:30 PM on ABC (US)

    airwords = invalid
    studio = invalid
    if itemData.status = "Ended"
        verb = "Aired"
    else
        verb = "Airs"
    end if

    airdays = itemData.airdays
    airtime = itemData.airtime
    if airtime <> invalid and airdays.count() = 1
        airwords = airdays[0] + " at " + airtime
    end if

    if itemData.studios.count() > 0
        studio = itemData.studios[0].name
    end if

    if studio = invalid and airwords = invalid
        m.top.findNode("main_group").removeChild(m.top.findNode("history"))
        return ""
    end if

    words = verb
    if airwords <> invalid
        words = words + " " + airwords
    end if
    if studio <> invalid
        words = words + " on " + studio
    end if

    return words
end function

function round(f as float) as integer
    ' BrightScript only has a "floor" round
    ' This compares floor to floor + 1 to find which is closer
    m = int(f)
    n = m + 1
    x = abs(f - m)
    y = abs(f - n)
    if y > x
        return m
    else
        return n
    end if
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    overview = m.top.findNode("overview")
    topGrp = m.top.findNode("seasons")
    bottomGrp = m.top.findNode("extrasGrid")

    if key = "down" and overview.hasFocus()
        topGrp.setFocus(true)
        return true
    else if key = "down" and topGrp.hasFocus()
        bottomGrp.setFocus(true)
        m.top.findNode("VertSlider").reverse = false
        m.top.findNode("extrasFader").reverse = false
        m.top.findNode("pplAnime").control = "start"
        return true
    else if key = "up" and bottomGrp.hasFocus()
        if bottomGrp.itemFocused = 0
            m.top.findNode("VertSlider").reverse = true
            m.top.findNode("extrasFader").reverse = true
            m.top.findNode("pplAnime").control = "start"
            topGrp.setFocus(true)
            return true
        end if
    else if key = "up" and topGrp.hasFocus()
        overview.setFocus(true)
        return true
    end if

    return false
end function
