sub init()
    m.api = API()
    m.top.functionName = "GetRunningTasks"
end sub

sub GetRunningTasks()
    m.top.response = m.api.scheduledtasks.get()
end sub

