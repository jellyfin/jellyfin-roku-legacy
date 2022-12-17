sub init()
    m.top.functionName = "loadItems"

    m.top.limit = 60
    usersettingLimit = get_user_setting("itemgrid.Limit")

    if usersettingLimit <> invalid
        m.top.limit = usersettingLimit
    end if
end sub

sub loadItems()
    results = []

    sort_field = m.top.sortField

    if m.top.sortAscending = true
        sort_order = "Ascending"
    else
        sort_order = "Descending"
    end if

    if m.top.ItemType = "LogoImage"
        logoImageExists = api_API().items.headimageurlbyname(m.top.itemId, "logo")
        if logoImageExists
            m.top.content = [api_API().items.getimageurl(m.top.itemId, "logo", 0, { "maxHeight": 500, "maxWidth": 500, "quality": "90" })]
        else
            m.top.content = []
        end if

        return
    end if

    params = {
        limit: m.top.limit,
        StartIndex: m.top.startIndex,
        parentid: m.top.itemId,
        SortBy: sort_field,
        SortOrder: sort_order,
        recursive: m.top.recursive,
        Fields: "Overview",
        StudioIds: m.top.studioIds,
        genreIds: m.top.genreIds
    }

    ' Handle special case when getting names starting with numeral
    if m.top.NameStartsWith <> ""
        if m.top.NameStartsWith = "#"
            if m.top.ItemType = "LiveTV" or m.top.ItemType = "TvChannel"
                params.searchterm = "A"
                params.append({ parentid: " " })
            else
                params.NameLessThan = "A"
            end if
        else
            if m.top.ItemType = "LiveTV" or m.top.ItemType = "TvChannel"
                params.searchterm = m.top.nameStartsWith
                params.append({ parentid: " " })
            else
                params.NameStartsWith = m.top.nameStartsWith
            end if
        end if
    end if

    'reset data
    if LCase(m.top.searchTerm) = LCase(tr("all"))
        params.searchTerm = " "
    else if m.top.searchTerm <> ""
        params.searchTerm = m.top.searchTerm
    end if

    filter = LCase(m.top.filter)
    if filter = "all"
        ' do nothing
    else if filter = "favorites"
        params.append({ Filters: "IsFavorite" })
        params.append({ isFavorite: true })
    end if

    if m.top.ItemType <> ""
        params.append({ IncludeItemTypes: m.top.ItemType })
    end if

    if m.top.ItemType = "LiveTV"
        url = "LiveTv/Channels"
        params.append({ UserId: get_setting("active_user") })
    else if m.top.view = "Networks"
        url = "Studios"
        params.append({ UserId: get_setting("active_user") })
    else if m.top.view = "Genres"
        url = "Genres"
        params.append({ UserId: get_setting("active_user") })
    else if m.top.ItemType = "MusicArtist"
        url = "Artists"
        params.append({
            UserId: get_setting("active_user")
        })
        params.IncludeItemTypes = ""
    else if m.top.ItemType = "MusicAlbum"
        url = Substitute("Users/{0}/Items/", get_setting("active_user"))
        params.append({ ImageTypeLimit: 1 })
        params.append({ EnableImageTypes: "Primary,Backdrop,Banner,Thumb" })
    else
        url = Substitute("Users/{0}/Items/", get_setting("active_user"))
    end if
    resp = APIRequest(url, params)
    data = getJson(resp)
    if data <> invalid

        if data.TotalRecordCount <> invalid then m.top.totalRecordCount = data.TotalRecordCount

        for each item in data.Items
            tmp = invalid
            if item.Type = "Movie" or item.Type = "MusicVideo"
                tmp = CreateObject("roSGNode", "MovieData")
            else if item.Type = "Series"
                tmp = CreateObject("roSGNode", "SeriesData")
            else if item.Type = "BoxSet" or item.Type = "ManualPlaylistsFolder"
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
            else if item.type = "Episode"
                tmp = CreateObject("roSGNode", "TVEpisode")
            else if item.Type = "Genre"
                tmp = CreateObject("roSGNode", "ContentNode")
                tmp.title = item.name

                genreData = api_API().users.getitemsbyquery(get_setting("active_user"), {
                    SortBy: "Random",
                    SortOrder: "Ascending",
                    IncludeItemTypes: "Movie",
                    Recursive: true,
                    Fields: "PrimaryImageAspectRatio,MediaSourceCount,BasicSyncInfo",
                    ImageTypeLimit: 1,
                    EnableImageTypes: "Primary",
                    Limit: 6,
                    GenreIds: item.id,
                    EnableTotalRecordCount: false,
                    ParentId: m.top.itemId
                })

                if genreData.Items.Count() > 5
                    ' Add View All item to the start of the row
                    row = tmp.createChild("FolderData")
                    row.parentFolder = m.top.itemId
                    genreMovieImage = api_API().items.getimageurl(item.id)
                    row.title = item.name
                    row.json = item
                    row.FHDPOSTERURL = genreMovieImage
                    row.HDPOSTERURL = genreMovieImage
                    row.SDPOSTERURL = genreMovieImage
                    row.type = "Folder"
                end if

                for each genreMovie in genreData.Items
                    row = tmp.createChild("MovieData")

                    genreMovieImage = api_API().items.getimageurl(genreMovie.id)
                    row.title = genreMovie.name
                    row.FHDPOSTERURL = genreMovieImage
                    row.HDPOSTERURL = genreMovieImage
                    row.SDPOSTERURL = genreMovieImage
                    row.json = genreMovie
                    row.id = genreMovie.id
                    row.type = genreMovie.type
                end for

            else if item.Type = "Studio"
                tmp = CreateObject("roSGNode", "FolderData")
            else if item.Type = "MusicAlbum"
                tmp = CreateObject("roSGNode", "MusicAlbumData")
                tmp.type = "MusicAlbum"
                if api_API().items.headimageurlbyname(item.id, "primary")
                    tmp.posterURL = ImageURL(item.id, "Primary")
                else
                    tmp.posterURL = ImageURL(item.id, "backdrop")
                end if
            else if item.Type = "MusicArtist"
                tmp = CreateObject("roSGNode", "MusicArtistData")
            else if item.Type = "Audio"
                tmp = CreateObject("roSGNode", "MusicSongData")
            else
                print "[LoadItems] Unknown Type: " item.Type
            end if

            if tmp <> invalid
                if item.Type <> "Genre"
                    tmp.parentFolder = m.top.itemId
                    tmp.json = item
                    if item.UserData <> invalid and item.UserData.isFavorite <> invalid
                        tmp.favorite = item.UserData.isFavorite
                    end if
                end if

                results.push(tmp)
            end if
        end for
    end if
    m.top.content = results
end sub
