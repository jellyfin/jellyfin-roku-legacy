import "pkg:/source/api/UserLibrary.brs"
import "pkg:/source/api/baserequest.brs"
import "pkg:/source/utils/config.brs"

sub init()
    m.top.functionName = "setFavoriteStatus"
end sub

sub setFavoriteStatus()

    task = m.top.favTask

    if task = "Favorite"
        MarkItemFavorite(m.top.itemId)
    else if task = "Unfavorite"
        UnmarkItemFavorite(m.top.itemId)
    end if

end sub
