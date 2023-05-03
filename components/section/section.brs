import "pkg:/source/utils/misc.brs"

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

    m.scrollUpToOnDeckAnimation = m.top.findNode("scrollUpToOnDeckAnimation")
    m.scrollUpToOnDeckPosition = m.top.findNode("scrollUpToOnDeckPosition")

    m.scrollDownToOnDeckAnimation = m.top.findNode("scrollDownToOnDeckAnimation")
    m.scrollDownToOnDeckPosition = m.top.findNode("scrollDownToOnDeckPosition")

    m.scrollOffOnDeckAnimation = m.top.findNode("scrollOffOnDeckAnimation")
    m.scrollOffOnDeckPosition = m.top.findNode("scrollOffOnDeckPosition")

    m.top.observeField("translation", "onTranslationChange")
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

    m.scrollUpToOnDeckPosition.fieldToInterp = m.top.id + ".translation"

    m.scrollDownToOnDeckPosition.fieldToInterp = m.top.id + ".translation"

    m.scrollOffOnDeckPosition.fieldToInterp = m.top.id + ".translation"
end sub

sub onTranslationChange()
    m.startingPosition = m.top.translation
    m.scrollOffBottomPosition.keyValue = "[[0, 0], [" + str(m.startingPosition[0]) + ", " + str(m.startingPosition[1]) + "]]"
    m.top.unobserveField("translation")
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

sub scrollUpToOnDeck()
    m.scrollUpToOnDeckAnimation.control = "start"
end sub

sub scrollDownToOnDeck()
    m.scrollDownToOnDeckAnimation.control = "start"
end sub

sub scrollOffOnDeck()
    m.scrollOffOnDeckAnimation.control = "start"
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
