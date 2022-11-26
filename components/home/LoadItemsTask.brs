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

        maxDaysInNextUp = get_user_setting("ui.details.maxdaysnextup", "365")
        if isValid(maxDaysInNextUp)
            maxDaysInNextUp = Val(maxDaysInNextUp)
            if maxDaysInNextUp > 0
                dateToday = CreateObject("roDateTime")
                dateCutoff = CreateObject("roDateTime")

                dateCutoff.FromSeconds(dateToday.AsSeconds() - (maxDaysInNextUp * 86400))

                params["NextUpDateCutoff"] = dateCutoff.ToISOString()
                params["EnableRewatching"] = false
                params["DisableFirstEpisode"] = false
                params["limit"] = 24
            end if
        end if

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
            ' Skip Books for now as we don't support it (issue #558)
            if item.Type <> "Book"
                tmp = CreateObject("roSGNode", "HomeData")
                tmp.json = item
                results.push(tmp)
            end if
        end for

    else if m.top.itemsToLoad = "favorites"

        url = Substitute("Users/{0}/Items", get_setting("active_user"))

        params = {}
        params["Filters"] = "IsFavorite"
        params["Limit"] = 20
        params["recursive"] = true
        params["sortby"] = "random"

        resp = APIRequest(url, params)
        data = getJson(resp)
        for each item in data.Items
            ' Skip Books for now as we don't support it (issue #558)
            if item.Type <> "Book"
                tmp = CreateObject("roSGNode", "HomeData")
                tmp.json = item
                results.push(tmp)
            end if
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

        ' Extract array of persons from Views and download full metadata for each
    else if m.top.itemsToLoad = "people"
        for each person in m.top.peopleList
            tmp = CreateObject("roSGNode", "ExtrasData")
            tmp.Id = person.Id
            tmp.labelText = person.Name
            params = {}
            params["Tags"] = person.PrimaryImageTag
            params["MaxWidth"] = 234
            params["MaxHeight"] = 330
            tmp.posterURL = ImageUrl(person.Id, "Primary", params)
            tmp.json = person
            results.push(tmp)
        end for
    else if m.top.itemsToLoad = "specialfeatures"
        params = {}
        url = Substitute("Users/{0}/Items/{1}/SpecialFeatures", get_setting("active_user"), m.top.itemId)
        resp = APIRequest(url, params)
        data = getJson(resp)
        if data <> invalid and data.count() > 0
            for each specfeat in data
                tmp = CreateObject("roSGNode", "ExtrasData")
                results.push(tmp)
                params = {}
                params["Tags"] = specfeat.ImageTags.Primary
                params["MaxWidth"] = 450
                params["MaxHeight"] = 402
                tmp.posterURL = ImageUrl(specfeat.Id, "Primary", params)
                tmp.json = specfeat
            end for
        end if
    else if m.top.itemsToLoad = "likethis"
        params = { "userId": get_setting("active_user"), "limit": 16 }
        url = Substitute("Items/{0}/Similar", m.top.itemId)
        resp = APIRequest(url, params)
        data = getJson(resp)
        for each item in data.items
            tmp = CreateObject("roSGNode", "ExtrasData")
            tmp.posterURL = ImageUrl(item.Id, "Primary", { "Tags": item.PrimaryImageTag })
            tmp.json = item
            results.push(tmp)
        end for
    else if m.top.itemsToLoad = "personMovies"
        getPersonVideos("Movie", results, {})
    else if m.top.itemsToLoad = "personTVShows"
        getPersonVideos("Episode", results, { MaxWidth: 502, MaxHeight: 300 })
    else if m.top.itemsToLoad = "personSeries"
        getPersonVideos("Series", results, {})
    else if m.top.itemsToLoad = "metaData"
        results.push(ItemMetaData(m.top.itemId))
    else if m.top.itemsToLoad = "audioStream"
        results.push(AudioStream(m.top.itemId))
    else if m.top.itemsToLoad = "backdropImage"
        results.push(BackdropImage(m.top.itemId))
    end if

    m.top.content = results

end sub

sub getPersonVideos(videoType, dest, dimens)
    params = { personIds: m.top.itemId, recursive: true, includeItemTypes: videoType, Limit: 50, SortBy: "Random" }
    url = Substitute("Users/{0}/Items", get_setting("active_user"))
    resp = APIRequest(url, params)
    data = getJson(resp)
    if data <> invalid and data.count() > 0
        for each item in data.items
            tmp = CreateObject("roSGNode", "ExtrasData")
            imgParms = { "Tags": item.ImageTags.Primary }
            imgParms.append(dimens)
            tmp.posterURL = ImageUrl(item.Id, "Primary", imgParms)
            tmp.json = item
            dest.push(tmp)
        end for
    end if
end sub
