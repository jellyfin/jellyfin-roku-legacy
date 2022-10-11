sub init()
    m.top.id = "overhang"
    ' hide seperators till they're needed
    leftSeperator = m.top.findNode("overlayLeftSeperator")
    leftSeperator.visible = "false"
    m.rightSeperator = m.top.findNode("overlayRightSeperator")

    m.hideClock = get_user_setting("ui.design.hideclock") = "true"

    ' set font sizes
    optionText = m.top.findNode("overlayOptionsText")
    optionText.font.size = 20
    optionStar = m.top.findNode("overlayOptionsStar")
    optionStar.font.size = 58
    overlayMeridian = m.top.findNode("overlayMeridian")
    overlayMeridian.font.size = 20

    m.overlayRightGroup = m.top.findNode("overlayRightGroup")
    m.overlayTimeGroup = m.top.findNode("overlayTimeGroup")

    m.slideDownAnimation = m.top.findNode("slideDown")
    m.slideUpAnimation = m.top.findNode("slideUp")

    if not m.hideClock
        ' get system preference clock format (12/24hr)
        di = CreateObject("roDeviceInfo")
        m.clockFormat = di.GetClockFormat()
        m.overlayHours = m.top.findNode("overlayHours")
        m.overlayMinutes = m.top.findNode("overlayMinutes")
        m.overlayMeridian = m.top.findNode("overlayMeridian")

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
    leftSeperator = m.top.findNode("overlayLeftSeperator")
    if m.top.title <> ""
        leftSeperator.visible = "true"
    else
        leftSeperator.visible = "false"
    end if
    title = m.top.findNode("overlayTitle")
    title.text = m.top.title

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
    m.currentTime = CreateObject("roDateTime")
    m.currentTime.ToLocalTime()
    m.currentTimeTimer.duration = 60 - m.currentTime.GetSeconds()
    m.currentHours = m.currentTime.GetHours()
    m.currentMinutes = m.currentTime.GetMinutes()
    updateTimeDisplay()
end sub

sub resetTime()
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
    optionText = m.top.findNode("overlayOptionsText")
    optionStar = m.top.findNode("overlayOptionsStar")
    if m.top.showOptions = true
        optionText.visible = true
        optionStar.visible = true
    else
        optionText.visible = false
        optionStar.visible = false
    end if
end sub
