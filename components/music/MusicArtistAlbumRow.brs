sub init()
    m.top.itemComponentName = "ListPoster"
    m.top.rowFocusAnimationStyle = "fixedFocusWrap"
    m.top.showRowLabel = [false]
    m.top.showRowCounter = [true]

    getData()
    updateSize()

    m.top.setfocus(true)
end sub

sub updateSize()
    itemWidth = 200
    itemHeight = 320 ' width * 1.5 + text

    m.top.visible = true

    ' size of the whole row
    m.top.itemSize = [1700, (itemHeight + 40)]
    
    ' spacing between rows
    m.top.itemSpacing = [0, 0]

    ' size of the item in the row
    m.top.rowItemSize = [itemWidth, itemHeight]

    ' spacing between items in a row
    m.top.rowItemSpacing = [10, 0]
end sub

function getData()
    ' If we have no album data, return a blank node
    if m.top.MusicArtistAlbumData = invalid
        data = CreateObject("roSGNode", "ContentNode")
        return data
    end if

    albumData = m.top.MusicArtistAlbumData
    data = CreateObject("roSGNode", "ContentNode")
    row = data.CreateChild("ContentNode")

    for each album in albumData.items
        row.appendChild(album)
    end for

    m.top.content = data

    return data
end function
