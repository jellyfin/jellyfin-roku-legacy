sub init()
    m.top.optionsAvailable = false
end sub

sub itemContentChanged()
    m.LoadLibrariesTask = createObject("roSGNode", "LoadPhotoTask")
    m.LoadLibrariesTask.itemContent = m.top.itemContent
    m.LoadLibrariesTask.observeField("results", "onPhotoLoaded")
    m.LoadLibrariesTask.control = "RUN"
end sub

sub onPhotoLoaded()
    if m.LoadLibrariesTask.results <> invalid
        photo = m.top.findNode("photo")
        photo.uri = m.LoadLibrariesTask.results
    else
        'Show user error here (for example if it's not a supported image type)
        message_dialog("This image type is not supported.") 
    end if
end sub
