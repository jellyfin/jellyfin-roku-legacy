import "pkg:/source/roku_modules/log/LogMixin.brs"

sub init()
    m.log = log.Logger("SceneManager")
    m.groups = []
    m.scene = m.top.getScene()
    m.content = m.scene.findNode("content")
    m.overhang = m.scene.findNode("overhang")
end sub

'
' Push a new group onto the stack, replacing the existing group on the screen
sub pushScene(newGroup)

    currentGroup = m.groups.peek()
    if newGroup <> invalid
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
                currentGroup.setFocus(false)
            end if

            if currentGroup.isSubType("JFGroup")
                unregisterOverhangData(currentGroup)
            end if

            currentGroup.visible = false

            if currentGroup.isSubType("JFScreen")
                currentGroup.callFunc("OnScreenHidden")
            end if

        end if

        m.groups.push(newGroup)

        if currentGroup <> invalid
            m.content.replaceChild(newGroup, 0)
        else
            m.content.appendChild(newGroup)
        end if

        if newGroup.isSubType("JFScreen")
            newGroup.callFunc("OnScreenShown")
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
    else
        currentGroup.focusedChild.setFocus(true)
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

        group.visible = false

        if group.isSubType("JFScreen")
            group.callFunc("OnScreenHidden")
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

        if group.isSubType("JFScreen")
            group.callFunc("OnScreenShown")
        else
            ' Restore focus
            if group.lastFocus <> invalid
                group.lastFocus.setFocus(true)
            else
                if group.focusedChild <> invalid
                    group.focusedChild.setFocus(true)
                else
                    group.setFocus(true)
                end if
            end if
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
' Clear previous scene from group stack
sub clearPreviousScene()
    m.groups.pop()
end sub

'
' Delete scene from group stack at passed index
sub deleteSceneAtIndex(index = 1)
    m.groups.Delete(index)
end sub

'
' Display user/device settings screen
sub settings()
    settingsScreen = createObject("roSGNode", "Settings")
    pushScene(settingsScreen)
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
        m.log.error("registerOverhangData(): Unexpected group type.", group, group.subtype())
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
    dialog = createObject("roSGNode", "StandardMessageDialog")
    dialog.title = title
    dialog.message = message
    dialog.buttons = [tr("OK")]
    dialog.observeField("buttonSelected", "dismissDialog")
    m.scene.dialog = dialog
end sub

'
' Display dialog to user with an OK button
sub standardDialog(title, message)
    dialog = createObject("roSGNode", "StandardDialog")
    dlgPalette = createObject("roSGNode", "RSGPalette")
    dlgPalette.colors = {
        DialogBackgroundColor: "0x262828FF",
        DialogFocusColor: "0xcececeFF",
        DialogFocusItemColor: "0x202020FF",
        DialogSecondaryTextColor: "0xf8f8f8ff",
        DialogSecondaryItemColor: "#00a4dcFF",
        DialogTextColor: "0xeeeeeeFF"
    }
    dialog.palette = dlgPalette
    dialog.observeField("buttonSelected", "dismissDialog")
    dialog.title = title
    dialog.contentData = message
    dialog.buttons = [tr("OK")]

    m.scene.dialog = dialog
end sub

'
' Display dialog to user with an OK button
sub radioDialog(title, message)
    dialog = createObject("roSGNode", "RadioDialog")
    dlgPalette = createObject("roSGNode", "RSGPalette")
    dlgPalette.colors = {
        DialogBackgroundColor: "0x262828FF",
        DialogFocusColor: "0xcececeFF",
        DialogFocusItemColor: "0x202020FF",
        DialogSecondaryTextColor: "0xf8f8f8ff",
        DialogSecondaryItemColor: "#00a4dcFF",
        DialogTextColor: "0xeeeeeeFF"
    }
    dialog.palette = dlgPalette
    dialog.observeField("buttonSelected", "dismissDialog")
    dialog.title = title
    dialog.contentData = message
    dialog.buttons = [tr("OK")]

    m.scene.dialog = dialog
end sub

'
' Display dialog to user with an OK button
sub optionDialog(title, message, buttons)
    m.top.dataReturned = false
    m.top.returnData = invalid
    m.userselection = false

    dialog = createObject("roSGNode", "StandardMessageDialog")
    dlgPalette = createObject("roSGNode", "RSGPalette")
    dlgPalette.colors = {
        DialogBackgroundColor: "0x262828FF",
        DialogFocusColor: "0xcececeFF",
        DialogFocusItemColor: "0x202020FF",
        DialogSecondaryTextColor: "0xf8f8f8ff",
        DialogSecondaryItemColor: "#00a4dcFF",
        DialogTextColor: "0xeeeeeeFF"
    }
    dialog.palette = dlgPalette
    dialog.observeField("buttonSelected", "optionSelected")
    dialog.observeField("wasClosed", "optionClosed")
    dialog.title = title
    dialog.message = message
    dialog.buttons = buttons

    m.scene.dialog = dialog
end sub

'
' Return button the user selected
sub optionClosed()
    if m.userselection then return

    m.top.returnData = {
        indexSelected: -1,
        buttonSelected: ""
    }
    m.top.dataReturned = true
end sub

'
' Return button the user selected
sub optionSelected()
    m.userselection = true
    m.top.returnData = {
        indexSelected: m.scene.dialog.buttonSelected,
        buttonSelected: m.scene.dialog.buttons[m.scene.dialog.buttonSelected]
    }
    m.top.dataReturned = true

    dismissDialog()
end sub

'
' Close currently displayed dialog
sub dismissDialog()
    m.scene.dialog.close = true
end sub

'
' Returns bool indicating if dialog is currently displayed
function isDialogOpen() as boolean
    return m.scene.dialog <> invalid
end function
