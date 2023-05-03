sub init()
    m.top.functionName = "monitorQuickConnect"
end sub

sub monitorQuickConnect()
    authenticated = checkQuickConnect(m.top.secret)

    if authenticated = true
        m.top.authenticated = 1
    else
        m.top.authenticated = -1
    end if
end sub
