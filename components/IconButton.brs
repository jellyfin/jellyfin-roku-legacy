sub init()
    m.buttonBackground = m.top.findNode("buttonBackground")
    m.buttonIcon = m.top.findNode("buttonIcon")
    m.buttonText = m.top.findNode("buttonText")

    m.top.observeField("background", "onBackgroundChanged")
    m.top.observeField("icon", "onIconChanged")
    m.top.observeField("text", "onTextChanged")
    m.top.observeField("height", "onHeightChanged")
    m.top.observeField("width", "onWidthChanged")
    m.top.observeField("padding", "onPaddingChanged")
    m.top.observeField("focusedChild", "onFocusChanged")
end sub

sub onFocusChanged()
    if m.top.hasFocus()
        m.buttonBackground.blendColor = m.top.focusBackground
    else
        m.buttonBackground.blendColor = m.top.background
    end if
end sub

sub onBackgroundChanged()
    m.buttonBackground.blendColor = m.top.background
    m.top.unobserveField("background")
end sub

sub onIconChanged()
    m.buttonIcon.uri = m.top.icon
end sub

sub onTextChanged()
    m.buttonText.text = m.top.text
end sub

sub setIconSize()
    height = m.buttonBackground.height
    width = m.buttonBackground.width
    if height > 0 and width > 0
        ' TODO: Use smallest number between them
        m.buttonIcon.height = m.top.height

        if m.top.padding > 0
            m.buttonIcon.height = m.buttonIcon.height - m.top.padding
        end if

        m.buttonIcon.width = m.buttonIcon.height

        m.buttonIcon.translation = [((width - m.buttonIcon.width) / 2), ((height - m.buttonIcon.height) / 2)]
        m.buttonText.translation = [0, height + 10]
        m.buttonText.width = width
    end if
end sub

sub onHeightChanged()
    m.buttonBackground.height = m.top.height
    setIconSize()
end sub

sub onWidthChanged()
    m.buttonBackground.width = m.top.width
    setIconSize()
end sub

sub onPaddingChanged()
    setIconSize()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "OK" and m.top.hasFocus()
        ' Simply toggle the selected field to trigger the next event
        m.top.selected = not m.top.selected
        return true
    end if

    return false
end function
