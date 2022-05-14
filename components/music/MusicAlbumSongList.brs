sub init()
    m.top.content = getData()
    m.top.setfocus(true)
end sub

function getData()
    if m.top.MusicArtistAlbumData = invalid
        data = CreateObject("roSGNode", "ContentNode")
        return data
    end if

    albumData = m.top.MusicArtistAlbumData
    data = CreateObject("roSGNode", "ContentNode")

    for each song in albumData.items
        songcontent = data.createChild("ContentNode")
        songcontent.title = song.title
    end for

    m.top.content = data

    return data
end function