sub init()
    m.top.functionName = "getScreensaverTimeout"
end sub

sub getScreensaverTimeout()
    appinfo = CreateObject("roAppManager")
    m.top.content = appinfo.GetScreensaverTimeout() * 60
end sub
