import "pkg:/source/api/Items.brs"
import "pkg:/source/roku_modules/api/api.brs"
import "pkg:/source/api/baserequest.brs"
import "pkg:/source/utils/config.brs"
import "pkg:/source/utils/misc.brs"
import "pkg:/source/api/Image.brs"
import "pkg:/source/utils/deviceCapabilities.brs"
import "pkg:/source/roku_modules/log/LogMixin.brs"

sub init()
    m.log = log.Logger("LoadItemsTask2")
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
    else if filter = "unplayed"
        params.append({ Filters: "IsUnplayed" })
    else if filter = "played"
        params.append({ Filters: "IsPlayed" })
    else if filter = "resumable"
        params.append({ Filters: "IsResumable" })
    end if

    if isValid(m.top.filterOptions)
        if m.top.filterOptions.count() > 0
            params.append(m.top.filterOptions)
        end if
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
        params.append({ UserId: get_setting("active_user"), includeItemTypes: m.top.itemType })
    else if m.top.ItemType = "MusicArtist"
        url = "Artists"
        params.append({
            UserId: get_setting("active_user"),
            Fields: "Genres"
        })
        params.IncludeItemTypes = "MusicAlbum,Audio"
    else if m.top.ItemType = "AlbumArtists"
        url = "Artists/AlbumArtists"
        params.append({
            UserId: get_setting("active_user"),
            Fields: "Genres"
        })
        params.IncludeItemTypes = "MusicAlbum,Audio"
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
            else if item.Type = "Video" or item.Type = "Recording"
                tmp = CreateObject("roSGNode", "VideoData")
            else if item.Type = "Photo"
                tmp = CreateObject("roSGNode", "PhotoData")
            else if item.type = "PhotoAlbum"
                tmp = CreateObject("roSGNode", "FolderData")
            else if item.type = "Playlist"
                tmp = CreateObject("roSGNode", "PlaylistData")
                tmp.type = "Playlist"
                tmp.image = PosterImage(item.id, { "maxHeight": 425, "maxWidth": 290, "quality": "90" })
            else if item.type = "Episode"
                tmp = CreateObject("roSGNode", "TVEpisode")
            else if item.Type = "Genre"
                tmp = CreateObject("roSGNode", "ContentNode")
                tmp.title = item.name

                genreData = api_API().users.getitemsbyquery(get_setting("active_user"), {
                    SortBy: "Random",
                    SortOrder: "Ascending",
                    IncludeItemTypes: m.top.itemType,
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
                    row.title = tr("View All") + " " + item.name
                    item.name = tr("View All") + " " + item.name
                    row.json = item
                    row.type = "Folder"

                    if LCase(m.top.itemType) = "movie"
                        genreItemImage = api_API().items.getimageurl(item.id)
                    else
                        genreItemImage = invalid
                        row.posterURL = invalid
                    end if

                    row.FHDPOSTERURL = genreItemImage
                    row.HDPOSTERURL = genreItemImage
                    row.SDPOSTERURL = genreItemImage
                end if

                for each genreItem in genreData.Items
                    if LCase(m.top.itemType) = "movie"
                        row = tmp.createChild("MovieData")
                    else
                        row = tmp.createChild("SeriesData")
                    end if

                    genreItemImage = api_API().items.getimageurl(genreItem.id)
                    row.title = genreItem.name
                    row.FHDPOSTERURL = genreItemImage
                    row.HDPOSTERURL = genreItemImage
                    row.SDPOSTERURL = genreItemImage
                    row.json = genreItem
                    row.id = genreItem.id
                    row.type = genreItem.type
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
                tmp.type = "Audio"
                tmp.image = api_API().items.getimageurl(item.id, "primary", 0, { "maxHeight": 280, "maxWidth": 280, "quality": "90" })
            else if item.Type = "MusicGenre"
                tmp = CreateObject("roSGNode", "FolderData")
                tmp.title = item.name
                tmp.parentFolder = m.top.itemId
                tmp.json = item
                tmp.type = "Folder"
                tmp.posterUrl = api_API().items.getimageurl(item.id, "primary", 0, { "maxHeight": 280, "maxWidth": 280, "quality": "90" })

            else
                m.log.warn("Unknown Type", item.Type)
            end if

            if tmp <> invalid
                if item.Type <> "Genre" and item.Type <> "MusicGenre"
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
