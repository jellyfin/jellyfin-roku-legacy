sub init()
    m.top.functionName = "getShuffleEpisodesTask"
end sub

sub getShuffleEpisodesTask()
    data = api_API().shows.getepisodes(m.top.showID, {
        UserId: m.global.session.user.id,
        SortBy: "Random",
        Limit: 200
    })

    m.top.data = data
end sub
