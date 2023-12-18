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
        songcontent = data.createChild("MusicSongData")
        songcontent.json = song.json
    end for

    m.top.content = data

    m.top.doneLoading = true

    return data
end function
