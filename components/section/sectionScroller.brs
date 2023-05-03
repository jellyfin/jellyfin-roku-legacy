import "pkg:/source/utils/misc.brs"

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

    onDeckSection = invalid
    previouslyOnDeckSection = invalid

    if m.top.displayedIndex + 1 <= (m.top.getChildCount() - 1)
        onDeckSection = m.top.getChild(m.top.displayedIndex + 1)
    end if

    if m.top.displayedIndex + 2 <= (m.top.getChildCount() - 1)
        previouslyOnDeckSection = m.top.getChild(m.top.displayedIndex + 2)
    end if

    ' Move sections either up or down depending on what index we're moving to
    if m.top.displayedIndex > m.previouslyDisplayedSection
        for i = m.previouslyDisplayedSection to m.top.displayedIndex - 1
            m.top.getChild(i).callFunc("scrollOffTop")
        end for

        displayedSection.callFunc("showFromBottom")
        if isValid(onDeckSection)
            onDeckSection.callFunc("scrollUpToOnDeck")
        end if
    else if m.top.displayedIndex < m.previouslyDisplayedSection
        m.top.getChild(m.top.displayedIndex + 1).callFunc("scrollDownToOnDeck")
        displayedSection.callFunc("showFromTop")

        if isValid(previouslyOnDeckSection)
            previouslyOnDeckSection.callFunc("scrollOffOnDeck")
        end if
    end if

    m.previouslyDisplayedSection = m.top.displayedIndex
end sub
