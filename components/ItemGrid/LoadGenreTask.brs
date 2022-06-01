sub init()
    m.top.functionName = "loadGenre"
end sub

sub loadGenre()
    url = "Genres"

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
        Fields: "Overview",
        IncludeItemTypes: "",
        userId: get_setting("active_user"),
        IncludeItemTypes: m.top.ItemType
    }


    ' Handle special case when getting names starting with numeral
    if m.top.NameStartsWith <> ""
        if m.top.NameStartsWith = "#"
            params.NameLessThan = "A"
        else
            params.NameStartsWith = m.top.nameStartsWith
        end if
    end if

    filter = m.top.filter
    if filter = "All" or filter = "all"
        ' do nothing
    else if filter = "Favorites"
        params.append({ Filters: "IsFavorite" })
        params.append({ isFavorite: true })
    end if

    resp = APIRequest(url, params)
    data = getJson(resp)

    if data <> invalid

        if data.TotalRecordCount <> invalid then m.top.totalRecordCount = data.TotalRecordCount

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
            else if item.Type = "Studio"
                tmp = CreateObject("roSGNode", "FolderData")
            else if item.Type = "Genre"
                tmp = CreateObject("roSGNode", "FolderData")
            else
                print "[LoadNetworks] Unknown Type: " item.Type
            end if

            if tmp <> invalid
                tmp.parentFolder = m.top.itemId
                tmp.json = item
                results.push(tmp)
            end if
        end for
    end if
    m.top.content = results
end sub
