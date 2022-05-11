sub init()
    m.top.itemComponentName = "ListPoster"
    m.top.content = getData()

    m.top.rowFocusAnimationStyle = "fixedFocusWrap"

    m.top.showRowLabel = [false]
    m.top.showRowCounter = [true]
    m.top.rowLabelOffset = [0, 0]

    updateSize()

    m.top.setfocus(true)
end sub

sub updateSize()
    itemWidth = 200
    itemHeight = 320 ' width * 1.5 + text

    m.top.visible = true

    ' size of the whole row
    m.top.itemSize = [1800, (itemHeight + 40)]
    ' spacing between rows
    m.top.itemSpacing = [0, 0]

    ' size of the item in the row
    m.top.rowItemSize = [itemWidth, itemHeight]
    ' spacing between items in a row
    m.top.rowItemSpacing = [0, 0]
end sub

function getData()
    if m.top.TVSeasonData = invalid
        data = CreateObject("roSGNode", "ContentNode")
        return data
    end if

    seasonData = m.top.TVSeasonData
    data = CreateObject("roSGNode", "ContentNode")
    row = data.CreateChild("ContentNode")
    row.title = "Seasons"
    for each item in seasonData.items
        row.appendChild(item)
    end for
    m.top.content = data
    return data
end function
