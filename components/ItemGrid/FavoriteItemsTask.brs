sub init()
    m.top.functionName = "loadFavorites"
end sub

sub loadFavorites()

    task = m.top.favTask

    if task = "Favorite"
        MarkItemFavorite(m.top.itemId)
    end if

end sub