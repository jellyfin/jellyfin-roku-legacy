import "pkg:/source/utils/config.brs"
import "pkg:/source/roku_modules/api/api.brs"

sub init()
    m.top.functionName = "getShuffleEpisodesTask"
end sub

sub getShuffleEpisodesTask()
    data = api_API().shows.getepisodes(m.top.showID, {
        UserId: get_setting("active_user"),
        SortBy: "Random",
        Limit: 200
    })

    m.top.data = data
end sub
