sub init()
    getData()
    m.top.infocus = false
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
        gridAlbum.shortdescriptionline1 = album.title
        gridAlbum.HDGRIDPOSTERURL = album.posterURL
        gridAlbum.hdposterurl = album.posterURL
        gridAlbum.SDGRIDPOSTERURL = album.SDGRIDPOSTERURL
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
            m.top.infocus = false
            return true
        end if
    end if

    return false
end function
