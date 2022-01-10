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
            tmp = CreateObject("roSGNode", "HomeData")
            tmp.json = item
            results.push(tmp)
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
            tmp = CreateObject("roSGNode", "HomeData")
            tmp.json = item
            results.push(tmp)
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
        ' Load a Person's Metadata
    else if m.top.itemsToLoad = "person"
        params = {}

        url = Substitute("Users/{0}/Items/{1}", get_setting("active_user"), m.top.itemId)
        resp = APIRequest(url, params)
        data = getJson(resp)
        ' We only have one item  and need only the data
        results.push(data)

        ' Extract array of persons from Views and download full metadata for each
    else if m.top.itemsToLoad = "people"
        params = {}
        for each person in m.top.peopleList
            tmp = CreateObject("roSGNode", "ExtrasData")
            tmp.Id = person.Id
            tmp.labelText = person.Name
            tmp.subTitle = person.Type
            tmp.posterURL = ImageUrl(person.Id, "Primary", {"Tags": person.PrimaryImageTag})
            results.push(tmp)
        end for
    else if m.top.itemsToLoad = "imageurl"
        results.push(ImageUrl(m.top.itemId, "Primary", m.top.metadata))
    end if

    m.top.content = results

end sub
