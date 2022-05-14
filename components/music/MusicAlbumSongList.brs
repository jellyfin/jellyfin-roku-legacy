sub init()
    m.top.content = getData()
    m.top.setfocus(true)
end sub

function getData()
    if m.top.MusicArtistAlbumData = invalid
        data = CreateObject("roSGNode", "ContentNode")
        return data
    end if

    seasonData = m.top.MusicArtistAlbumData
    data = CreateObject("roSGNode", "ContentNode")
    
    for each item in seasonData.items
        itemcontent = data.createChild("ContentNode")
        itemcontent.title = item.title
    end for

    m.top.content = data

    return data
end function