import "pkg:/source/utils/config.brs"
import "pkg:/source/api/sdk.bs"

sub init()
    m.top.functionName = "GetItemQueryTask"
end sub

sub getItemQueryTask()
    if not m.top.live = "true"

        m.getItemQueryTask = api.users.getitemsbyquery(get_setting("active_user"), {
            ids: m.top.videoID,
            fields: "Overview,People"
        })
    else
        m.getItemQueryTask = api.livetv.getprograms({
            channelIds: m.top.videoID,
            isAiring: "true",
            fields: "People,Overview"
        })
    end if
    m.top.getItemQueryData = m.getItemQueryTask
    print "running ItemQuery Task: " m.top.getItemQueryData
end sub

