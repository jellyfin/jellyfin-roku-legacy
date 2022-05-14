sub init()
    m.top.optionsAvailable = false
    main = m.top.findNode("toplevel")
    main.translation = [96, 175]
end sub

sub itemContentChanged()
    item = m.top.itemContent
    itemData = item.json

    ' Populate scene data
    m.top.overhangTitle = itemData.name
    m.top.findNode("musicArtistPoster").uri = m.top.itemContent.posterURL
    setFieldText("overview", itemData.overview)
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

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    return false
end function
