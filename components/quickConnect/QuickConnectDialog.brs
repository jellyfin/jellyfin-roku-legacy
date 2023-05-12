import "pkg:/source/api/userauth.brs"
import "pkg:/source/api/baserequest.brs"
import "pkg:/source/utils/config.brs"
import "pkg:/source/utils/session.bs"

sub init()
    m.quickConnectTimer = m.top.findNode("quickConnectTimer")
    m.quickConnectTimer.observeField("fire", "quickConnectStatus")
    m.quickConnectTimer.control = "start"
    m.top.observeFieldScoped("buttonSelected", "onButtonSelected")
end sub

sub quickConnectStatus()
    m.quickConnectTimer.control = "stop"
    m.checkTask = CreateObject("roSGNode", "QuickConnect")
    m.checkTask.secret = m.top.quickConnectJson.secret
    m.checkTask.observeField("authenticated", "OnAuthenticated")
    m.checkTask.control = "run"
end sub

sub OnAuthenticated()
    m.checkTask.unobserveField("authenticated")

    ' Did we get the A-OK to authenticate?
    authenticated = m.checkTask.authenticated
    if authenticated < 0
        ' Still waiting, check again in 3 seconds...
        authenticated = 0
        m.checkTask.observeField("authenticated", "OnAuthenticated")
        m.quickConnectTimer.control = "start"
    else if authenticated > 0
        ' We've been given the go ahead, try to authenticate via Quick Connect...
        authenticated = AuthenticateViaQuickConnect(m.top.quickConnectJson.secret)
        if authenticated <> invalid and authenticated = true
            currentUser = AboutMe()
            session.user.Login(currentUser)
            LoadUserPreferences()
            LoadUserAbilities()
            m.top.close = true
            m.top.authenticated = true
        else
            m.top.close = true
            m.top.authenticated = false
        end if
    end if
end sub

sub quickConnectClosed()
    m.quickConnectTimer.control = "stop"
    if m.checkTask <> invalid
        m.checkTask.unobserveField("authenticated")
    end if
    m.top.close = true
end sub

sub onButtonSelected()
    ' only one button at the moment...
    quickConnectClosed()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    ' Note that "OK" does not get sent here, hence onButtonSelected() above.
    if key = "back"
        quickConnectClosed()
        return true
    end if

    return false
end function
