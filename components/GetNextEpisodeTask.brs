sub init()
    m.top.functionName = "getNextEpisodeTask"
end sub

sub getNextEpisodeTask()
    m.nextEpisodeData = api_API().shows.getepisodes(m.top.showID, {

        userId: get_setting("active_user"),
        StartItemId: m.top.videoID,
        limit: 2,
        fields: "Overview,People"

    })

    m.top.nextEpisodeData = m.nextEpisodeData
end sub
