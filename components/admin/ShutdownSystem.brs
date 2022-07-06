sub init()
    m.api = API()
    m.top.functionName = "ShutdownSystem"
end sub

sub ShutdownSystem()
    m.api.system.shutdown()
end sub

