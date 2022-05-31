sub init()
    m.top.functionName = "loadProgramDetails"

end sub

sub loadProgramDetails()

    channelIndex = m.top.ChannelIndex
    programIndex = m.top.ProgramIndex

    params = {
        UserId: get_setting("active_user")
    }

    url = Substitute("LiveTv/Programs/{0}", m.top.programId)

    resp = APIRequest(url, params)
    data = getJson(resp)

    if data = invalid
        m.top.programDetails = {}
        return
    end if

    program = createObject("roSGNode", "ScheduleProgramData")
    program.json = data
    program.channelIndex = channelIndex
    program.programIndex = programIndex
    program.fullyLoaded = true
    ' Are we currently recording this program?
    if program.json.TimerId <> invalid and program.json.TimerId <> ""
        ' This is needed here because the callee (onProgramDetailsLoaded) replaces the grid item with
        ' this newly created item from the server, without this, the red icon
        ' disappears when the user focuses on the program in question
        program.hdSmallIconUrl = "pkg:/images/red.png"
    else
        program.hdSmallIconUrl = invalid
    end if
    m.top.programDetails = program

end sub
