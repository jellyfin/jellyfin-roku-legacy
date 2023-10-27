import "pkg:/source/api/Items.brs"
import "pkg:/source/api/baserequest.brs"
import "pkg:/source/utils/config.brs"
import "pkg:/source/api/Image.brs"
import "pkg:/source/utils/deviceCapabilities.brs"

sub init()
    m.top.itemComponentName = "ListPoster"
    m.top.content = getData()

    updateSize()

    m.top.showRowLabel = [true]
    m.top.rowLabelOffset = [0, 20]
    m.top.showRowCounter = [true]

    ' TODO - Define a failed to load image background
    ' m.top.failedBitmapURI

end sub

sub updateSize()
    ' In search results, rowSize only dictates how many are on screen at once
    m.top.rowSize = 3

    dimensions = m.top.getScene().currentDesignResolution

    border = 50
    m.top.translation = [border, border + 115]

    textHeight = 80
    itemWidth = (dimensions["width"] - border) / 6
    itemHeight = itemWidth + (textHeight / 2.3)

    m.top.itemSize = [1350, itemHeight] ' this is used for setting the row size
    m.top.itemSpacing = [0, 105]

    m.top.rowItemSize = [itemWidth, itemHeight]
    m.top.rowItemSpacing = [0, 0]
    m.top.numRows = 2
    m.top.translation = "[12,18]"
end sub

function getData()
    if m.top.itemData = invalid
        data = CreateObject("roSGNode", "ContentNode")
        return data
    end if

    itemData = m.top.itemData

    ' todo - Or get the old data? I can't remember...
    data = CreateObject("roSGNode", "ContentNode")
    ' Do this to keep the ordering, AssociateArrays have no order
    type_array = ["Movie", "Series", "TvChannel", "Episode", "MusicArtist", "MusicAlbum", "Audio", "Person", "PlaylistsFolder"]
    content_types = {
        "TvChannel": { "label": "Channels", "count": 0 },
        "Movie": { "label": "Movies", "count": 0 },
        "Series": { "label": "Shows", "count": 0 },
        "Episode": { "label": "Episodes", "count": 0 },
        "MusicArtist": { "label": "Artists", "count": 0 },
        "MusicAlbum": { "label": "Albums", "count": 0 },
        "Audio": { "label": "Songs", "count": 0 },
        "Person": { "label": "People", "count": 0 },
        "PlaylistsFolder": { "label": "Playlist", "count": 0 }
    }

    for each item in itemData.Items
        if content_types[item.type] <> invalid
            content_types[item.type].count += 1
        end if
    end for

    for each ctype in type_array
        content_type = content_types[ctype]
        if content_type.count > 0
            addRow(data, content_type.label, ctype)
        end if
    end for

    m.top.content = data
    return data
end function

sub addRow(data, title, type_filter)
    itemData = m.top.itemData
    row = data.CreateChild("ContentNode")
    row.title = title
    for each item in itemData.Items
        if item.type = type_filter
            row.appendChild(item)
        end if
    end for
end sub
