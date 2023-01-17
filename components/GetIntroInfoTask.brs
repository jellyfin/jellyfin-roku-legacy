sub init()
    m.top.functionName = "getIntroInfoTask"
end sub

sub getIntroInfoTask()
    api_retval = api_API().introskipper.get(m.top.videoID)
    if api_retval = invalid or type(api_retval) <> "roAssociativeArray" or api_retval.Valid <> true
        m.introData = invalid
        m.top.introData = invalid
    else
        m.introData = api_retval
        m.top.introData = api_retval
    end if
end sub
