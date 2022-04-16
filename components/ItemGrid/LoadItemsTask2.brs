sub init()
    m.top.functionName = "loadItems"
end sub

sub loadItems()

    results = []

    sort_field = m.top.sortField

    if m.top.sortAscending = true
        sort_order = "Ascending"
    else
        sort_order = "Descending"
    end if


    params = {
        limit: m.top.limit,
        StartIndex: m.top.startIndex,
        parentid: m.top.itemId,
        SortBy: sort_field,
        SortOrder: sort_order,
        recursive: m.top.recursive,
        Fields: "Overview"
    }

    filter = m.top.filter
    if filter = "All" or filter = "all"
        ' do nothing
    else if filter = "Favorites"
        params.append({ Filters: "IsFavorite" })
        params.append({ isFavorite: true })
    else if filter = "A"
        params.append({ NameStartsWith: "A" })
    else if filter = "B"
        params.append({ NameStartsWith: "B" })
    else if filter = "C"
        params.append({ NameStartsWith: "C" })
    else if filter = "D"
        params.append({ NameStartsWith: "D" })
    else if filter = "E"
        params.append({ NameStartsWith: "E" })
    else if filter = "F"
        params.append({ NameStartsWith: "F" })
    else if filter = "G"
        params.append({ NameStartsWith: "G" })
    else if filter = "H"
        params.append({ NameStartsWith: "H" })
    else if filter = "I"
        params.append({ NameStartsWith: "I" })
    else if filter = "J"
        params.append({ NameStartsWith: "J" })
    else if filter = "K"
        params.append({ NameStartsWith: "K" })
    else if filter = "L"
        params.append({ NameStartsWith: "L" })
    else if filter = "M"
        params.append({ NameStartsWith: "M" })
    else if filter = "N"
        params.append({ NameStartsWith: "N" })
    else if filter = "O"
        params.append({ NameStartsWith: "O" })
    else if filter = "P"
        params.append({ NameStartsWith: "P" })
    else if filter = "Q"
        params.append({ NameStartsWith: "Q" })
    else if filter = "R"
        params.append({ NameStartsWith: "R" })
    else if filter = "S"
        params.append({ NameStartsWith: "S" })
    else if filter = "T"
        params.append({ NameStartsWith: "T" })
    else if filter = "U"
        params.append({ NameStartsWith: "U" })
    else if filter = "V"
        params.append({ NameStartsWith: "V" })
    else if filter = "W"
        params.append({ NameStartsWith: "W" })
    else if filter = "X"
        params.append({ NameStartsWith: "X" })
    else if filter = "Y"
        params.append({ NameStartsWith: "Y" })
    else if filter = "Z"
        params.append({ NameStartsWith: "Z" })
    end if

    if m.top.ItemType <> ""
        params.append({ IncludeItemTypes: m.top.ItemType })
    end if

    if m.top.ItemType = "LiveTV"
        url = "LiveTv/Channels"
        params.append({ userId: get_setting("active_user") })
    else
        url = Substitute("Users/{0}/Items/", get_setting("active_user"))
    end if
    resp = APIRequest(url, params)
    data = getJson(resp)

    if data.TotalRecordCount <> invalid
        m.top.totalRecordCount = data.TotalRecordCount
    end if

    for each item in data.Items

        tmp = invalid
        if item.Type = "Movie"
            tmp = CreateObject("roSGNode", "MovieData")
        else if item.Type = "Series"
            tmp = CreateObject("roSGNode", "SeriesData")
        else if item.Type = "BoxSet"
            tmp = CreateObject("roSGNode", "CollectionData")
        else if item.Type = "TvChannel"
            tmp = CreateObject("roSGNode", "ChannelData")
        else if item.Type = "Folder" or item.Type = "ChannelFolderItem" or item.Type = "CollectionFolder"
            tmp = CreateObject("roSGNode", "FolderData")
        else if item.Type = "Video"
            tmp = CreateObject("roSGNode", "VideoData")
        else if item.Type = "Photo"
            tmp = CreateObject("roSGNode", "PhotoData")
        else if item.type = "PhotoAlbum"
            tmp = CreateObject("roSGNode", "FolderData")
        else
            print "[LoadItems] Unknown Type: " item.Type
        end if

        if tmp <> invalid

            tmp.json = item
            results.push(tmp)

        end if
    end for

    m.top.content = results

end sub