import "pkg:/source/utils/config.brs"
import "pkg:/source/api/sdk.bs"

sub init()
    m.top.functionName = "getShuffleEpisodesTask"
end sub

sub getShuffleEpisodesTask()
    data = api.shows.GetEpisodes(m.top.showID, {
        UserId: m.global.session.user.id,
        SortBy: "Random",
        Limit: 200
    })

    m.top.data = data
end sub
