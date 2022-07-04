sub init()
    m.top.overhangTitle = tr("Admin Dashboard")
    m.top.optionsAvailable = false

    m.screens = {}
    m.screens.append({
        Dashboard: m.top.findNode("dashboard"),
        General: m.top.findNode("general")
    })

    m.leftNav = m.top.findNode("leftNav")
    m.leftNav.observeField("itemFocused", "onItemFocused")
    m.leftNav.setFocus(true)

    m.dashboard = m.top.findNode("dashboard")
    m.dashboardButtons = m.top.findNode("dashboardButtons")

    m.LoadServerData = CreateObject("roSGNode", "LoadServerData")
    m.LoadServerData.observeField("content", "onServerDataLoaded")
    m.LoadServerData.control = "RUN"

    m.btnRestart = m.top.findNode("btn.restart")
    m.btnScan = m.top.findNode("btn.scan")

    m.server = m.top.findNode("server")
    m.version = m.top.findNode("version")
    m.os = m.top.findNode("os")
    m.arch = m.top.findNode("arch")

    m.cachepath = m.top.findNode("cachepath")
    m.logspath = m.top.findNode("logspath")
    m.metadatapath = m.top.findNode("metadatapath")
    m.transcodespath = m.top.findNode("transcodespath")
    m.webpath = m.top.findNode("webpath")
end sub

sub onServerDataLoaded()
    data = m.LoadServerData.content
    m.LoadServerData.unobserveField("content")
    if isValid(data)
        m.server.text = m.server.text + data.ServerName
        m.version.text = m.version.text + data.Version
        m.os.text = m.os.text + data.OperatingSystemDisplayName
        m.arch.text = m.arch.text + data.SystemArchitecture

        m.cachepath.text = m.cachepath.text + data.CachePath
        m.logspath.text = m.logspath.text + data.LogPath
        m.metadatapath.text = m.metadatapath.text + data.InternalMetadataPath
        m.transcodespath.text = m.transcodespath.text + data.TranscodingTempPath
        m.webpath.text = m.webpath.text + data.WebPath
    end if
end sub

'
'Handle new item being focused
sub onItemFocused()
    hideScreens()

    selection = m.leftNav.content.getChild(m.leftNav.itemFocused)
    showScreen(selection)
end sub

sub hideScreens()
    for each screen in m.screens
        m.screens[screen].visible = false
    end for
end sub

sub showScreen(selection)
    screen = m.screens[selection.title]
    if screen = invalid then return
    screen.visible = true
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if key = "right" and m.leftNav.hasFocus()
        if m.dashboard.visible
            m.dashboardButtons.setFocus(true)
            return true
        end if
    else if key = "left" and m.dashboard.isInFocusChain() and m.dashboardButtons.buttonFocused = 0
        if not press then return false
        m.leftNav.setFocus(true)
        return true
    else if key = "OK"
        if m.btnRestart.hasFocus()
            print "RESTART"
            return true
        else if m.btnScan.hasFocus()
            print "START SCAN"
            return true
        end if
    end if

    return false
end function
