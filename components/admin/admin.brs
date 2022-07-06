sub init()
    m.api = API()
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

    m.GetSystemInfo = CreateObject("roSGNode", "GetSystemInfo")
    m.GetSystemInfo.observeField("response", "onControllerResponse")
    m.GetSystemInfo.control = "RUN"

    m.btnShutdown = m.top.findNode("btn.shutdown")
    m.btnScan = m.top.findNode("btn.scan")

    m.server = m.top.findNode("server")
    m.version = m.top.findNode("version")
    m.os = m.top.findNode("os")
    m.arch = m.top.findNode("arch")
    m.scanpercent = m.top.findNode("scanpercent")

    m.cachepath = m.top.findNode("cachepath")
    m.logspath = m.top.findNode("logspath")
    m.metadatapath = m.top.findNode("metadatapath")
    m.transcodespath = m.top.findNode("transcodespath")
    m.webpath = m.top.findNode("webpath")

    m.GetRunningTasks = CreateObject("roSGNode", "GetRunningTasks")
    m.GetRunningTasks.observeField("response", "onRunningTaskResponse")
    m.runningtaskcomplete = true
end sub

sub onControllerResponse()
    data = m.GetSystemInfo.response
    m.GetSystemInfo.unobserveField("response")
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

sub onRunningTaskResponse()
    m.scanpercent.visible = true
    data = m.GetRunningTasks.response

    for each task in data
        if task.name = "Scan Media Library"
            if task.CurrentProgressPercentage = invalid
                if not m.runningtaskcomplete
                    m.runningtaskcomplete = true
                    m.scanpercent.visible = false
                    return
                end if

                m.GetRunningTasks.control = "STOP"
                m.GetRunningTasks.control = "RUN"
            else
                m.runningtaskcomplete = false
                m.scanpercent.text = task.CurrentProgressPercentage.toStr() + "%"
                m.GetRunningTasks.control = "STOP"
                m.GetRunningTasks.control = "RUN"
            end if
        end if
    end for

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
        m.hideLeftNavAnimation = m.top.findNode("hideLeftNavAnimation")
        m.hideLeftNavAnimation.control = "start"

        if m.dashboard.visible
            m.dashboardButtons.setFocus(true)
            return true
        end if
    else if key = "left" and m.dashboard.isInFocusChain() and m.dashboardButtons.buttonFocused = 0
        if not press then return false
        m.showLeftNavAnimation = m.top.findNode("showLeftNavAnimation")
        m.showLeftNavAnimation.control = "start"

        m.leftNav.setFocus(true)
        return true
    else if key = "OK"
        if m.btnShutdown.hasFocus()
            m.ShutdownSystem = CreateObject("roSGNode", "ShutdownSystem")
            m.ShutdownSystem.control = "RUN"
            return true
        else if m.btnScan.hasFocus()
            m.LibraryRefresh = CreateObject("roSGNode", "LibraryRefresh")
            m.LibraryRefresh.control = "RUN"

            m.GetRunningTasks.control = "RUN"
            return true
        end if
    end if

    return false
end function
