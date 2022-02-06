sub init()
    m.top.functionName = "loadItems"
end sub

sub loadItems()
    item = m.top.itemContent

    group = CreateObject("roSGNode", "PhotoDetails")
    group.optionsAvailable = false
    m.global.sceneManager.callFunc("pushScene", group)

    group.itemContent = item

    ' TODO/FIXME:
    ' Wait some time and move to the next photo...

end sub
