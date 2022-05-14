sub init()
    m.top.optionsAvailable = false
    main = m.top.findNode("toplevel")
    main.translation = [96, 175]
    m.extrasSlider = m.top.findNode("tvSeasonExtras")
    m.extrasSlider.visible = true
end sub

sub itemContentChanged()
    ' Updates video metadata
    ' TODO - make things use item rather than itemData
    item = m.top.itemContent
    itemData = item.json

    m.top.findNode("musicartistPoster").uri = m.top.itemContent.posterURL

    ' Handle all "As Is" fields
    m.top.overhangTitle = itemData.name

    setFieldText("overview", itemData.overview)

    if type(itemData.RunTimeTicks) = "LongInteger"
        setFieldText("runtime", stri(getRuntime()) + " mins")
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
