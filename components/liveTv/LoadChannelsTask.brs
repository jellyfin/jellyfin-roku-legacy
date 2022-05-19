sub init()
    m.top.functionName = "loadChannels"
end sub

sub loadChannels()

    results = []
    
    sort_field = m.top.sortField

    if m.top.sortAscending = true
        sort_order = "Ascending"
    else
        sort_order = "Descending"
    end if

    params = {
        includeItemTypes: "LiveTvChannel",
        SortBy: sort_field,
        SortOrder: sort_order,
        recursive: m.top.recursive,
    }

       ' Handle special case when getting names starting with numeral
       if m.top.NameStartsWith <> ""
        if m.top.NameStartsWith = "#"
            params.NameLessThan = "A"
        else
            params.NameStartsWith = m.top.nameStartsWith
        end if
    end if

    'Append voice search when there is text
    if m.top.searchTerm <> ""
        params.searchTerm = m.top.searchTerm
    end if

    if m.top.filter = "Favorites"
        params.append({ isFavorite: true })
    end if

    url = Substitute("Users/{0}/Items/", get_setting("active_user"))

    resp = APIRequest(url, params)
    data = getJson(resp)

    if data.TotalRecordCount = invalid
        m.top.channels = results
        return
    end if


    for each item in data.Items
        channel = createObject("roSGNode", "ChannelData")
        channel.json = item
        results.push(channel)
    end for
    m.top.channels = results

end sub
