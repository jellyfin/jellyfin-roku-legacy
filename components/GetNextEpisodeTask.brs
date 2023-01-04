sub init()
    m.top.functionName = "getNextEpisodeTask"
end sub

sub getNextEpisodeTask()
    m.nextEpisodeData = api_API().shows.getepisodes(m.top.showID, {
        UserId: get_setting("active_user"),
        StartItemId: m.top.videoID,
        Limit: 2
    })

    m.top.nextEpisodeData = m.nextEpisodeData
end sub
