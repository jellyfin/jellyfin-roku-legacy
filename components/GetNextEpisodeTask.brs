import "pkg:/source/utils/config.brs"
import "pkg:/source/api/sdk.bs"

sub init()
    m.top.functionName = "getNextEpisodeTask"
end sub

sub getNextEpisodeTask()
    m.nextEpisodeData = api.shows.getepisodes(m.top.showID, {
        UserId: m.global.session.user.id,
        StartItemId: m.top.videoID,
        limit: 2,
        fields: "Overview,People"

    })

    m.top.nextEpisodeData = m.nextEpisodeData
    print "running NextEpisode Task: " m.top.getItemQueryData
end sub
