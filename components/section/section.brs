sub init()
    m.showFromBottomAnimation = m.top.findNode("showFromBottomAnimation")
    m.showFromBottomPosition = m.top.findNode("showFromBottomPosition")
    m.showFromBottomOpacity = m.top.findNode("showFromBottomOpacity")

    m.showFromTopAnimation = m.top.findNode("showFromTopAnimation")
    m.showFromTopPosition = m.top.findNode("showFromTopPosition")
    m.showFromTopOpacity = m.top.findNode("showFromTopOpacity")

    m.scrollOffTopAnimation = m.top.findNode("scrollOffTopAnimation")
    m.scrollOffTopPosition = m.top.findNode("scrollOffTopPosition")
    m.scrollOffTopOpacity = m.top.findNode("scrollOffTopOpacity")

    m.scrollOffBottomAnimation = m.top.findNode("scrollOffBottomAnimation")
    m.scrollOffBottomPosition = m.top.findNode("scrollOffBottomPosition")
    m.scrollOffBottomOpacity = m.top.findNode("scrollOffBottomOpacity")

    m.top.observeField("id", "onIDChange")
    m.top.observeField("focusedChild", "onFocusChange")
end sub

sub onIDChange()
    m.showFromBottomPosition.fieldToInterp = m.top.id + ".translation"
    m.showFromBottomOpacity.fieldToInterp = m.top.id + ".opacity"

    m.showFromTopPosition.fieldToInterp = m.top.id + ".translation"
    m.showFromTopOpacity.fieldToInterp = m.top.id + ".opacity"

    m.scrollOffTopPosition.fieldToInterp = m.top.id + ".translation"
    m.scrollOffTopOpacity.fieldToInterp = m.top.id + ".opacity"

    m.scrollOffBottomPosition.fieldToInterp = m.top.id + ".translation"
    m.scrollOffBottomOpacity.fieldToInterp = m.top.id + ".opacity"
end sub

sub showFromTop()
    m.showFromTopAnimation.control = "start"
end sub

sub showFromBottom()
    m.showFromBottomAnimation.control = "start"
end sub

sub scrollOffBottom()
    m.scrollOffBottomAnimation.control = "start"
end sub

sub scrollOffTop()
    m.scrollOffTopAnimation.control = "start"
end sub

sub onFocusChange()
    defaultFocusElement = m.top.findNode(m.top.defaultFocusID)

    if isValid(defaultFocusElement)
        defaultFocusElement.setFocus(m.top.isInFocusChain())
        if isValid(defaultFocusElement.focus)
            defaultFocusElement.focus = m.top.isInFocusChain()
        end if
    end if
end sub
