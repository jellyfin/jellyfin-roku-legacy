sub init()
    m.top.functionName = "RecordOrCancelProgram"
end sub

sub RecordOrCancelProgram()
    if m.top.programDetails <> invalid
        ' Are we setting up a recording or canceling one?
        TimerId = invalid
        if m.top.programDetails.json.TimerId <> invalid and m.top.programDetails.json.TimerId <> ""
            TimerId = m.top.programDetails.json.TimerId
        end if

        if TimerId = invalid
            ' Setting up a recording...
            programId = m.top.programDetails.Id

            ' Get Live TV default params from server...
            url = "LiveTv/Timers/Defaults"
            params = {
                programId: programId
            }

            resp = APIRequest(url, params)
            data = getJson(resp)

            if data <> invalid
                ' Create recording timer...
                if m.top.recordSeries = true
                    url = "LiveTv/SeriesTimers"
                else
                    url = "LiveTv/Timers"
                end if
                resp = APIRequest(url)
                postJson(resp, FormatJson(data))
                m.top.programDetails.hdSmallIconUrl = "pkg:/images/red.png"
            else
                ' Error msg to user?
                print "Error getting Live TV Defaults from Server"
            end if
        else
            ' Cancelling a recording...
            if m.top.recordSeries = true
                TimerId = m.top.programDetails.json.SeriesTimerId
                url = Substitute("LiveTv/SeriesTimers/{0}", TimerId)
            else
                url = Substitute("LiveTv/Timers/{0}", TimerId)
            end if
            resp = APIRequest(url)
            deleteVoid(resp)
            m.top.programDetails.hdSmallIconUrl = invalid
        end if
    end if

    m.top.recordOperationDone = true
end sub
