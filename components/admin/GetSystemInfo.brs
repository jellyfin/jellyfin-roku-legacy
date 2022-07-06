sub init()
    m.api = API()
    m.top.functionName = "GetSystemInfo"
end sub

sub GetSystemInfo()
    m.top.response = m.api.system.getinfo()
end sub

