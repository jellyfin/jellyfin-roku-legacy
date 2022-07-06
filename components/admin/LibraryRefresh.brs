sub init()
    m.api = API()
    m.top.functionName = "LibraryRefresh"
end sub

sub LibraryRefresh()
    m.api.library.refresh()
end sub

