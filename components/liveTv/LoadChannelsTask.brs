sub init()
    m.top.functionName = "loadChannels"
end sub

sub loadChannels()

    results = []

    params = {
        UserId: get_setting("active_user")
    }

    if m.top.filter = "Favorites"
        params.append({ isFavorite: true })
    end if

    url = "LiveTv/Channels"

    resp = APIRequest(url, params)
    data = getJson(resp)

    if data.TotalRecordCount = invalid
        m.top.channels = results
        return
    end if


    for each item in data.Items
        channel = createObject("roSGNode", "ChannelData")
        channel.json = item
        if item.UserData <> invalid and item.UserData.isFavorite <> invalid
            channel.favorite = item.UserData.isFavorite
            if channel.favorite = true
                results.Unshift(channel)
            else
                results.push(channel)
            end if
        else
            results.push(channel)
        end if
    end for

    m.top.channels = results

end sub
