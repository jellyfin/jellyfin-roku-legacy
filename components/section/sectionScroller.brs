sub init()
    m.previouslyDisplayedSection = 0
end sub

sub onFocusChange()
    if m.top.focus
        m.top.getChild(m.top.displayedIndex).setFocus(true)
    end if
end sub

sub displayedIndexChanged()
    if not m.top.affectsFocus then return

    if m.top.displayedIndex < 0
        return
    end if

    if m.top.displayedIndex > (m.top.getChildCount() - 1)
        return
    end if

    m.top.getChild(m.previouslyDisplayedSection).setFocus(false)

    displayedSection = m.top.getChild(m.top.displayedIndex)
    displayedSection.setFocus(true)

    ' Move sections either up or down depending on what index we're moving to
    if m.top.displayedIndex > m.previouslyDisplayedSection
        m.top.getChild(m.previouslyDisplayedSection).callFunc("scrollOffTop")
        displayedSection.callFunc("showFromBottom")
    else if m.top.displayedIndex < m.previouslyDisplayedSection
        m.top.getChild(m.previouslyDisplayedSection).callFunc("scrollOffBottom")
        displayedSection.callFunc("showFromTop")
    end if

    m.previouslyDisplayedSection = m.top.displayedIndex
end sub
