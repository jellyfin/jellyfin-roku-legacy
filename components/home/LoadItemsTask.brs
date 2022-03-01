sub init()
    m.top.functionName = "loadItems"
end sub

sub loadItems()

    results = []

    ' Load Libraries
    if m.top.itemsToLoad = "libraries"

        url = Substitute("Users/{0}/Views/", get_setting("active_user"))
        resp = APIRequest(url)
        data = getJson(resp)
        for each item in data.Items
            ' Skip Books for now as we don't support it (issue #525)
            if item.CollectionType <> "books"
                tmp = CreateObject("roSGNode", "HomeData")
                tmp.json = item
                results.push(tmp)
            end if
        end for

        ' Load Latest Additions to Libraries
    else if m.top.itemsToLoad = "latest"

        url = Substitute("Users/{0}/Items/Latest", get_setting("active_user"))
        params = {}
        params["Limit"] = 16
        params["ParentId"] = m.top.itemId
        params["EnableImageTypes"] = "Primary,Backdrop,Thumb"
        params["ImageTypeLimit"] = 1

        resp = APIRequest(url, params)
        data = getJson(resp)

        for each item in data
            ' Skip Books for now as we don't support it (issue #525)
            if item.Type <> "Book"
                tmp = CreateObject("roSGNode", "HomeData")
                tmp.json = item
                results.push(tmp)
            end if
        end for

        ' Load Next Up
    else if m.top.itemsToLoad = "nextUp"

        url = "Shows/NextUp"
        params = {}
        params["recursive"] = true
        params["SortBy"] = "DatePlayed"
        params["SortOrder"] = "Descending"
        params["ImageTypeLimit"] = 1
        params["UserId"] = get_setting("active_user")

        resp = APIRequest(url, params)
        data = getJson(resp)
        for each item in data.Items
            tmp = CreateObject("roSGNode", "HomeData")
            tmp.json = item
            results.push(tmp)
        end for

        ' Load Continue Watching
    else if m.top.itemsToLoad = "continue"

        url = Substitute("Users/{0}/Items/Resume", get_setting("active_user"))

        params = {}
        params["recursive"] = true
        params["SortBy"] = "DatePlayed"
        params["SortOrder"] = "Descending"
        params["Filters"] = "IsResumable"

        resp = APIRequest(url, params)
        data = getJson(resp)
        for each item in data.Items
            tmp = CreateObject("roSGNode", "HomeData")
            tmp.json = item
            results.push(tmp)
        end for

    else if m.top.itemsToLoad = "onNow"
        url = "LiveTv/Programs/Recommended"
        params = {}
        params["userId"] = get_setting("active_user")
        params["isAiring"] = true
        params["limit"] = 16 ' 16 to be consistent with "Latest In"
        params["imageTypeLimit"] = 1
        params["enableImageTypes"] = "Primary,Thumb,Backdrop"
        params["enableTotalRecordCount"] = false
        params["fields"] = "ChannelInfo,PrimaryImageAspectRatio"

        resp = APIRequest(url, params)
        data = getJson(resp)
        for each item in data.Items
            tmp = CreateObject("roSGNode", "HomeData")
            item.ImageURL = ImageURL(item.Id)
            tmp.json = item
            results.push(tmp)
        end for
    end if

    m.top.content = results

end sub
