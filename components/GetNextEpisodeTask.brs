import "pkg:/source/utils/config.brs"
import "pkg:/source/api/sdk.bs"

sub init()
    m.top.functionName = "getNextEpisodeTask"
end sub

sub getNextEpisodeTask()
        m.nextEpisodeData = api_API().shows.getepisodes(m.top.showID, {
        UserId: m.global.session.user.id,
        StartItemId: m.top.videoID,
        limit: 2,
        fields: "Overview,People"

    })

    m.top.nextEpisodeData = m.nextEpisodeData
end sub
