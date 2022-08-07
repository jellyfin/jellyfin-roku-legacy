sub init()
    m.buttonBackground = m.top.findNode("buttonBackground")
    m.buttonIcon = m.top.findNode("buttonIcon")
    m.buttonText = m.top.findNode("buttonText")

    m.buttonText.visible = false

    m.originalWidth = 0

    m.top.observeField("background", "onBackgroundChanged")
    m.top.observeField("icon", "onIconChanged")
    m.top.observeField("text", "onTextChanged")
    m.top.observeField("height", "onHeightChanged")
    m.top.observeField("width", "onWidthChanged")
    m.top.observeField("padding", "onPaddingChanged")
    m.top.observeField("focusedChild", "onFocusChanged")
    
    m.top.observeField("highlighted", "onHighlightChanged")
end sub

sub onFocusChanged()
    if m.top.hasFocus()
        m.buttonText.visible = true
        m.buttonBackground.blendColor = m.top.focusBackground
        m.top.width = 200
    else
        m.buttonText.visible = false
        m.top.width = m.originalWidth
        onHighlightChanged()
    end if
end sub

sub onHighlightChanged()
    if m.top.highlighted
        m.buttonBackground.blendColor = m.top.highlightBackground
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

        m.buttonIcon.translation = [m.top.padding, ((height - m.buttonIcon.height) / 2)]
        m.buttonText.translation = [m.top.padding + m.buttonIcon.width + 10, 12]
    end if
end sub

sub onHeightChanged()
    m.buttonBackground.height = m.top.height
    setIconSize()
end sub

sub onWidthChanged()
    if m.originalWidth = 0
        m.originalWidth = m.top.width
    end if
    
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
