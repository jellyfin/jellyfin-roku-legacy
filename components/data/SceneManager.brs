sub init()
    m.groups = []
    m.scene = m.top.getScene()
    m.content = m.scene.findNode("content")
    m.overhang = m.scene.findNode("overhang")
end sub

'
' Push a new group onto the stack, replacing the existing group on the screen
sub pushScene(newGroup)
    currentGroup = m.groups.peek()
    if currentGroup <> invalid
        'Search through group and store off last focused item
        if currentGroup.focusedChild <> invalid
            focused = currentGroup.focusedChild
            while focused.hasFocus() = false
                focused = focused.focusedChild
            end while
            currentGroup.lastFocus = focused
            currentGroup.setFocus(false)
        else
            currentGroup.lastFocus = invalid
            currentGroup.setFocus(false)
        end if

        if currentGroup.isSubType("JFGroup")
            unregisterOverhangData(currentGroup)
        end if

        currentGroup.visible = false
    end if

    m.groups.push(newGroup)

    if currentGroup <> invalid
        m.content.replaceChild(newGroup, 0)
    else
        m.content.appendChild(newGroup)
    end if

    'observe info about new group, set overhang title, etc.
    if newGroup.isSubType("JFGroup")
        registerOverhangData(newGroup)

        ' Some groups set focus to a specific component within init(), so we don't want to
        ' change if that is the case.
        if newGroup.isInFocusChain() = false
            newGroup.setFocus(true)
        end if
    else if newGroup.isSubType("JFVideo")
        newGroup.setFocus(true)
        newGroup.control = "play"
        m.overhang.visible = false
    end if
end sub

'
' Remove the current group and load the last group from the stack
sub popScene()
    group = m.groups.pop()
    if group <> invalid
        if group.isSubType("JFGroup")
            unregisterOverhangData(group)
        else if group.isSubType("JFVideo")
            ' Stop video to make sure app communicates stop playstate to server
            group.control = "stop"
        end if
    else
        ' Exit app if for some reason we don't have anything on the stack
        m.scene.exit = true
    end if

    group = m.groups.peek()
    if group <> invalid
        registerOverhangData(group)

        if group.subtype() = "Home"
            currentTime = CreateObject("roDateTime").AsSeconds()
            if group.timeLastRefresh = invalid or (currentTime - group.timeLastRefresh) > 20
                group.timeLastRefresh = currentTime
                group.callFunc("refresh")
            end if
        end if

        group.visible = true

        m.content.replaceChild(group, 0)

        ' Restore focus
        if group.lastFocus <> invalid
            group.lastFocus.setFocus(true)
        else
            group.setFocus(true)
        end if
    else
        ' Exit app if the stack is empty after removing group
        m.scene.exit = true
    end if

end sub


'
' Return group at top of stack without removing
function getActiveScene() as object
    return m.groups.peek()
end function


'
' Clear all content from group stack
sub clearScenes()
    if m.content <> invalid then m.content.removeChildrenIndex(m.content.getChildCount(), 0)
    m.groups = []
end sub


'
' Register observers for overhang data
sub registerOverhangData(group)
    if group.isSubType("JFGroup")
        if group.overhangTitle <> invalid then m.overhang.title = group.overhangTitle

        if group.optionsAvailable
            m.overhang.showOptions = true
        else
            m.overhang.showOptions = false
        end if
        group.observeField("optionsAvailable", "updateOptions")

        group.observeField("overhangTitle", "updateOverhangTitle")

        if group.overhangVisible
            m.overhang.visible = true
        else
            m.overhang.visible = false
        end if
        group.observeField("overhangVisible", "updateOverhangVisible")
    else if group.isSubType("JFVideo")
        m.overhang.visible = false
    else
        print "registerOverhangData(): Unexpected group type."
    end if
end sub


'
' Remove observers for overhang data
sub unregisterOverhangData(group)
    group.unobserveField("overhangTitle")
end sub


'
' Update overhang title
sub updateOverhangTitle(msg)
    m.overhang.title = msg.getData()
end sub


'
' Update options availability
sub updateOptions(msg)
    m.overhang.showOptions = msg.getData()
end sub


'
' Update whether the overhang is visible or not
sub updateOverhangVisible(msg)
    m.overhang.visible = msg.getData()
end sub


'
' Update username in overhang
sub updateUser()
    ' Passthrough to overhang
    if m.overhang <> invalid then m.overhang.currentUser = m.top.currentUser
end sub


'
' Reset time
sub resetTime()
    ' Passthrough to overhang
    m.overhang.callFunc("resetTime")
end sub

'
' Display dialog to user with an OK button
sub userMessage(title as string, message as string)
    dialog = createObject("roSGNode", "Dialog")
    dialog.title = title
    dialog.message = message
    dialog.buttons = [tr("OK")]
    dialog.observeField("buttonSelected", "dismiss_dialog")
    m.scene.dialog = dialog
end sub

'
' Close currently displayed dialog
sub dismiss_dialog()
    print "Button Pressed"
    m.scene.dialog.close = true
end sub