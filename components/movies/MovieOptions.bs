sub init()

    m.buttons = m.top.findNode("buttons")
    m.buttons.buttons = [tr("Video"), tr("Audio")]
    m.buttons.selectedIndex = 0
    m.buttons.setFocus(true)

    m.selectedItem = 0
    m.selectedAudioIndex = 0
    m.selectedVideoIndex = 0

    m.menus = [m.top.findNode("videoMenu"), m.top.findNode("audioMenu")]

    m.videoNames = []
    m.audioNames = []

    ' Set button colors to global
    m.top.findNode("videoMenu").focusBitmapBlendColor = m.global.constants.colors.button
    m.top.findNode("audioMenu").focusBitmapBlendColor = m.global.constants.colors.button

    ' Animation
    m.fadeAnim = m.top.findNode("fadeAnim")
    m.fadeOutAnimOpacity = m.top.findNode("outOpacity")
    m.fadeInAnimOpacity = m.top.findNode("inOpacity")

    m.buttons.observeField("focusedIndex", "buttonFocusChanged")
    m.buttons.focusedIndex = m.selectedItem

end sub

sub optionsSet()
    '  Videos Tab
    if m.top.options.videos <> invalid
        viewContent = CreateObject("roSGNode", "ContentNode")
        index = 0
        selectedViewIndex = 0

        for each view in m.top.options.videos
            entry = viewContent.CreateChild("VideoTrackListData")
            entry.title = view.Title
            entry.description = view.Description
            entry.streamId = view.streamId
            entry.video_codec = view.video_codec
            m.videoNames.push(view.Name)
            if view.Selected <> invalid and view.Selected = true
                selectedViewIndex = index
                entry.selected = true
                m.top.videoStreamId = view.streamId
            end if
            index = index + 1
        end for

        m.menus[0].content = viewContent
        m.menus[0].jumpToItem = selectedViewIndex
        m.menus[0].checkedItem = selectedViewIndex
        m.selectedVideoIndex = selectedViewIndex
    end if

    '  audio Tab
    if m.top.Options.audios <> invalid
        audioContent = CreateObject("roSGNode", "ContentNode")
        index = 0
        selectedAudioIndex = 0

        for each audio in m.top.options.audios
            entry = audioContent.CreateChild("AudioTrackListData")
            entry.title = audio.Title
            entry.description = audio.Description
            entry.streamIndex = audio.StreamIndex
            m.audioNames.push(audio.Name)
            if audio.Selected <> invalid and audio.Selected = true
                selectedAudioIndex = index
                entry.selected = true
                m.top.audioStreamIndex = audio.streamIndex
            end if
            index = index + 1
        end for

        m.menus[1].content = audioContent
        m.menus[1].jumpToItem = selectedAudioIndex
        m.menus[1].checkedItem = selectedAudioIndex
        m.selectedAudioIndex = selectedAudioIndex
    end if

end sub

' Switch menu shown when button focus changes
sub buttonFocusChanged()
    if m.buttons.focusedIndex = m.selectedItem then return
    m.fadeOutAnimOpacity.fieldToInterp = m.menus[m.selectedItem].id + ".opacity"
    m.fadeInAnimOpacity.fieldToInterp = m.menus[m.buttons.focusedIndex].id + ".opacity"
    m.fadeAnim.control = "start"
    m.selectedItem = m.buttons.focusedIndex
end sub


function onKeyEvent(key as string, press as boolean) as boolean

    if key = "down" or (key = "OK" and m.top.findNode("buttons").hasFocus())
        m.top.findNode("buttons").setFocus(false)
        m.menus[m.selectedItem].setFocus(true)
        m.menus[m.selectedItem].drawFocusFeedback = true

        'If user presses down from button menu, focus first item.  If OK, focus checked item
        if key = "down"
            m.menus[m.selectedItem].jumpToItem = 0
        else
            m.menus[m.selectedItem].jumpToItem = m.menus[m.selectedItem].itemSelected
        end if

        return true
    else if key = "OK"
        if m.menus[m.selectedItem].isInFocusChain()
            selMenu = m.menus[m.selectedItem]
            selIndex = selMenu.itemSelected

            'Handle Videos menu
            if m.selectedItem = 0
                if m.selectedVideoIndex = selIndex
                else
                    selMenu.content.GetChild(m.selectedVideoIndex).selected = false
                    newSelection = selMenu.content.GetChild(selIndex)
                    newSelection.selected = true
                    m.selectedVideoIndex = selIndex
                    m.top.videoStreamId = newSelection.streamId
                    m.top.video_codec = newSelection.video_codec
                end if
                ' Then it is Audio options
            else if m.selectedItem = 1
                if m.selectedAudioIndex = selIndex
                else
                    selMenu.content.GetChild(m.selectedAudioIndex).selected = false
                    newSelection = selMenu.content.GetChild(selIndex)
                    newSelection.selected = true
                    m.selectedAudioIndex = selIndex
                    m.top.audioStreamIndex = newSelection.streamIndex
                end if
            end if

        end if
        return true
    else if key = "back" or key = "up"
        if m.menus[m.selectedItem].isInFocusChain()
            m.buttons.setFocus(true)
            m.menus[m.selectedItem].drawFocusFeedback = false
            return true
        end if
    else if key = "options"
        m.menus[m.selectedItem].drawFocusFeedback = false
        return false
    end if

    return false

end function
