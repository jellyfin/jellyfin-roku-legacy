sub init()
    m.top.id = "overhang"
    ' hide seperators till they're needed
    m.leftSeperator = m.top.findNode("overlayLeftSeperator")
    m.leftSeperator.visible = "false"
    m.rightSeperator = m.top.findNode("overlayRightSeperator")
    ' set font sizes
    m.optionText = m.top.findNode("overlayOptionsText")
    m.optionText.font.size = 20
    m.optionStar = m.top.findNode("overlayOptionsStar")
    m.optionStar.font.size = 58
    ' save node references
    m.title = m.top.findNode("overlayTitle")
    m.overlayRightGroup = m.top.findNode("overlayRightGroup")
    m.overlayTimeGroup = m.top.findNode("overlayTimeGroup")
    m.slideDownAnimation = m.top.findNode("slideDown")
    m.slideUpAnimation = m.top.findNode("slideUp")
    ' show clock based on user setting
    m.hideClock = get_user_setting("ui.design.hideclock") = "true"
    if not m.hideClock
        ' get system preference clock format (12/24hr)
        di = CreateObject("roDeviceInfo")
        m.clockFormat = di.GetClockFormat()
        ' save node references
        m.overlayHours = m.top.findNode("overlayHours")
        m.overlayMinutes = m.top.findNode("overlayMinutes")
        m.overlayMeridian = m.top.findNode("overlayMeridian")
        m.overlayMeridian.font.size = 20
        ' start timer
        m.currentTimeTimer = m.top.findNode("currentTimeTimer")
        m.currentTimeTimer.control = "start"
        m.currentTimeTimer.ObserveField("fire", "updateTime")
    end if

    setClockVisibility()
end sub

sub onVisibleChange()
    if m.top.disableMoveAnimation
        m.top.translation = [0, 0]
        return
    end if
    if m.top.isVisible
        m.slideDownAnimation.control = "start"
        return
    end if

    m.slideUpAnimation.control = "start"
end sub

sub updateTitle()
    if m.top.title <> ""
        m.leftSeperator.visible = "true"
    else
        m.leftSeperator.visible = "false"
    end if
    m.title.text = m.top.title

    if not m.hideClock
        resetTime()
    end if
end sub

sub setClockVisibility()
    if m.hideClock
        m.overlayRightGroup.removeChild(m.overlayTimeGroup)
    end if
end sub

sub setRightSeperatorVisibility()
    if m.hideClock
        m.top.removeChild(m.rightSeperator)
        return
    end if

    if m.top.currentUser <> ""
        m.rightSeperator.visible = "true"
    else
        m.rightSeperator.visible = "false"
    end if
end sub

sub updateUser()
    setRightSeperatorVisibility()
    user = m.top.findNode("overlayCurrentUser")
    user.text = m.top.currentUser
end sub

sub updateTime()
    currentTime = CreateObject("roDateTime")
    currentTime.ToLocalTime()
    m.currentTimeTimer.duration = 60 - currentTime.GetSeconds()
    m.currentHours = currentTime.GetHours()
    m.currentMinutes = currentTime.GetMinutes()
    updateTimeDisplay()
end sub

sub resetTime()
    if m.hideClock then return
    m.currentTimeTimer.control = "stop"
    m.currentTimeTimer.control = "start"
    updateTime()
end sub

sub updateTimeDisplay()
    if m.clockFormat = "24h"
        m.overlayMeridian.text = ""
        if m.currentHours < 10
            m.overlayHours.text = "0" + StrI(m.currentHours).trim()
        else
            m.overlayHours.text = m.currentHours
        end if
    else
        if m.currentHours < 12
            m.overlayMeridian.text = "AM"
            if m.currentHours = 0
                m.overlayHours.text = "12"
            else
                m.overlayHours.text = m.currentHours
            end if
        else
            m.overlayMeridian.text = "PM"
            if m.currentHours = 12
                m.overlayHours.text = "12"
            else
                m.overlayHours.text = m.currentHours - 12
            end if
        end if
    end if

    if m.currentMinutes < 10
        m.overlayMinutes.text = "0" + StrI(m.currentMinutes).trim()
    else
        m.overlayMinutes.text = m.currentMinutes
    end if
end sub

sub updateOptions()
    if m.top.showOptions = true
        m.optionText.visible = true
        m.optionStar.visible = true
    else
        m.optionText.visible = false
        m.optionStar.visible = false
    end if
end sub
