sub init()
    m.itemText = m.top.findNode("itemText")
    m.trackNumber = m.top.findNode("trackNumber")
    m.tracklength = m.top.findNode("tracklength")

    m.defaultTextColor = m.itemText.color
end sub

sub itemContentChanged()
    itemData = m.top.itemContent
    if itemData = invalid then return
    m.itemText.text = itemData.title
    if itemData.trackNumber <> 0
        m.trackNumber.text = itemData.trackNumber
    end if
    m.tracklength.text = ticksToHuman(itemData.length)
end sub

sub focusChanged()
    if m.top.itemHasFocus
        color = "#101010FF"
    else
        color = m.defaultTextColor
    end if

    m.itemText.color = color
    m.trackNumber.color = color
    m.tracklength.color = color
end sub
