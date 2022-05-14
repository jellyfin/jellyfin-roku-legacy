sub init()
    m.top.optionsAvailable = false
    main = m.top.findNode("toplevel")
    main.translation = [96, 175]
end sub

' Set values for displayed values on screen
sub itemContentChanged()
    item = m.top.itemContent

    m.top.findNode("musicartistPoster").uri = item.posterURL

    m.top.overhangTitle = item.json.AlbumArtist + " / " + item.json.name

    setFieldText("overview", item.json.overview)
    setFieldText("numberofsongs", stri(item.json.ChildCount) + " Tracks")

    if type(item.json.ProductionYear) = "roInt"
        setFieldText("released", "Released " + stri(item.json.ProductionYear))
    end if

    if item.json.genres.count() > 0
        setFieldText("genres", item.json.genres.join(", "))
    end if

    if type(item.json.RunTimeTicks) = "LongInteger"
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
    ' then 1/60 for seconds to minutes... 1/600,000,000
    return round(itemData.RunTimeTicks / 600000000.0)
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

    return false
end function
