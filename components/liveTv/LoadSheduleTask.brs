import "pkg:/source/api/baserequest.brs"
import "pkg:/source/utils/config.brs"

sub init()
    m.top.functionName = "loadSchedule"
end sub

sub loadSchedule()

    results = []

    params = {
        UserId: m.global.session.user.id,
        SortBy: "startDate",
        EnableImages: false,
        EnableTotalRecordCount: false,
        EnableUserData: false,
        channelIds: m.top.channelIds,
        MaxStartDate: m.top.endTime,
        MinEndDate: m.top.startTime
    }

    url = "LiveTv/Programs"

    resp = APIRequest(url)
    data = postJson(resp, FormatJson(params))

    if data = invalid
        m.top.schedule = results
        return
    end if

    results = []

    for each item in data.Items
        program = createObject("roSGNode", "ScheduleProgramData")
        program.json = item
        ' Are we currently recording this program?
        if program.json.TimerId <> invalid and program.json.TimerId <> ""
            program.hdSmallIconUrl = "pkg:/images/red.png"
        else
            program.hdSmallIconUrl = invalid
        end if
        results.push(program)
    end for


    m.top.schedule = results

end sub
