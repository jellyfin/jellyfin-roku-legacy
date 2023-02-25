sub init()
    m.itemPoster = m.top.findNode("itemPoster")
    m.postTextBackground = m.top.findNode("postTextBackground")
    m.posterText = m.top.findNode("posterText")
    m.posterText.font.size = 30
    m.backdrop = m.top.findNode("backdrop")

    m.itemPoster.observeField("loadStatus", "onPosterLoadStatusChanged")

    'Parent is MarkupGrid and it's parent is the ItemGrid
    m.topParent = m.top.GetParent().GetParent()

    'Get the imageDisplayMode for these grid items
    if m.topParent.imageDisplayMode <> invalid
        m.itemPoster.loadDisplayMode = m.topParent.imageDisplayMode
    end if

    m.gridTitles = get_user_setting("itemgrid.gridTitles")
    m.posterText.visible = false
    m.postTextBackground.visible = false

end sub

sub itemContentChanged()
    m.backdrop.blendColor = "#101010"

    m.posterText.visible = false
    m.postTextBackground.visible = false

    if isValid(m.topParent.showItemTitles)
        if LCase(m.topParent.showItemTitles) = "showalways"
            m.posterText.visible = true
            m.postTextBackground.visible = true
        end if
    end if

    itemData = m.top.itemContent

    if not isValid(itemData) then return

    if LCase(itemData.type) = "musicalbum"
        m.backdrop.uri = "pkg:/images/icons/album.png"
    else if LCase(itemData.type) = "musicartist"
        m.backdrop.uri = "pkg:/images/missingArtist.png"
    else if LCase(itemData.json.type) = "musicgenre"
        m.backdrop.uri = "pkg:/images/icons/musicFolder.png"
    end if

    m.itemPoster.uri = itemData.PosterUrl
    m.posterText.text = itemData.title

    'If Poster not loaded, ensure "blue box" is shown until loaded
    if m.itemPoster.loadStatus <> "ready"
        m.backdrop.visible = true
    end if
    if m.top.itemHasFocus then focusChanged()
end sub

'Display or hide title Visibility on focus change
sub focusChanged()
    if m.top.itemHasFocus = true
        m.posterText.repeatCount = -1
    else
        m.posterText.repeatCount = 0
    end if

    if isValid(m.topParent.showItemTitles)
        if LCase(m.topParent.showItemTitles) = "showonhover"
            m.posterText.visible = m.top.itemHasFocus
            m.postTextBackground.visible = m.posterText.visible
        end if
    end if
end sub

'Hide backdrop and text when poster loaded
sub onPosterLoadStatusChanged()
    if m.itemPoster.loadStatus = "ready"
        m.backdrop.visible = false
    end if
end sub
