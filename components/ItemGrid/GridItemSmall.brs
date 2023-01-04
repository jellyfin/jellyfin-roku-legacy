sub init()
    m.itemPoster = m.top.findNode("itemPoster")
    m.posterText = m.top.findNode("posterText")
    m.title = m.top.findNode("title")
    m.posterText.font.size = 30
    m.title.font.size = 25
    m.backdrop = m.top.findNode("backdrop")

    m.itemPoster.observeField("loadStatus", "onPosterLoadStatusChanged")

    'Parent is MarkupGrid and it's parent is the ItemGrid
    m.topParent = m.top.GetParent().GetParent()

    m.title.visible = false

    'Get the imageDisplayMode for these grid items
    if m.topParent.imageDisplayMode <> invalid
        m.itemPoster.loadDisplayMode = m.topParent.imageDisplayMode
    end if

end sub

sub itemContentChanged()
    m.backdrop.blendColor = "#101010"

    if isValid(m.topParent.showItemTitles)
        m.title.visible = m.topParent.showItemTitles
    end if

    itemData = m.top.itemContent

    if not isValid(itemData) then return

    m.itemPoster.uri = itemData.PosterUrl
    m.posterText.text = itemData.title
    m.title.text = itemData.title

    'If Poster not loaded, ensure "blue box" is shown until loaded
    if m.itemPoster.loadStatus <> "ready"
        m.backdrop.visible = true
        m.posterText.visible = true
    end if
end sub

sub focusChanged()

    if m.top.itemHasFocus = true
        m.title.repeatCount = -1
    else
        m.title.repeatCount = 0
    end if
end sub

'Hide backdrop and text when poster loaded
sub onPosterLoadStatusChanged()
    if m.itemPoster.loadStatus = "ready"
        m.backdrop.visible = false
        m.posterText.visible = false
    end if
end sub
