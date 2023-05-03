sub init()
    getData()
end sub

function getData()

    ' If we have no album data, return a blank node
    if m.top.MusicArtistAlbumData = invalid
        data = CreateObject("roSGNode", "ContentNode")
        return data
    end if

    albumData = m.top.MusicArtistAlbumData
    data = CreateObject("roSGNode", "ContentNode")

    for each album in albumData.items
        gridAlbum = CreateObject("roSGNode", "ContentNode")

        if not isValid(album.posterURL) or album.posterURL = ""
            album.posterURL = "pkg:/images/icons/album.png"
        end if

        gridAlbum.shortdescriptionline1 = album.title
        gridAlbum.HDGRIDPOSTERURL = album.posterURL
        gridAlbum.hdposterurl = album.posterURL
        gridAlbum.SDGRIDPOSTERURL = album.posterURL
        gridAlbum.sdposterurl = album.posterURL

        data.appendChild(gridAlbum)
    end for

    m.top.content = data

    return data
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "up"
        if m.top.itemFocused <= 4
            m.top.escape = key
            return true
        end if
    else if key = "left"
        if m.top.itemFocused mod 5 = 0
            m.top.escape = key
            return true
        end if
    else if key = "right"
        if m.top.itemFocused + 1 mod 5 = 0
            m.top.escape = key
            return true
        end if
    else if key = "down"
        totalCount = m.top.MusicArtistAlbumData.items.count()
        totalRows = div_ceiling(totalCount, 5)
        currentRow = div_ceiling(m.top.itemFocused + 1, 5)

        if currentRow = totalRows
            m.top.escape = key
            return true
        end if
    end if

    return false
end function
