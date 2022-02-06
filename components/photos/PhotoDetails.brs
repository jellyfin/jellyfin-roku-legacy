sub init()
    m.top.optionsAvailable = false  ' Change once Shuffle option is added
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
        ' Hide overhang so it's not overlayed on top of the photo
        m.global.sceneManager.callFunc("hideOverhang")
    else
        'Show user error here (for example if it's not a supported image type)
        message_dialog("This image type is not supported.")
    end if
end sub


function onKeyEvent(key as string, press as boolean) as boolean

    if not press then return false

    if key = "back"
        ' Restore overhang since it was hidden when showing the photo
        m.global.sceneManager.callFunc("showOverhang")
    end if

    return false
end function
