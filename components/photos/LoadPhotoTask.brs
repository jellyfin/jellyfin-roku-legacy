import "pkg:/source/api/Image.brs"
import "pkg:/source/utils/config.brs"
import "pkg:/source/api/baserequest.brs"

sub init()
    m.top.functionName = "loadItems"
end sub

sub loadItems()
    item = m.top.itemContent
    if item <> invalid
        params = {
            maxHeight: 1080,
            maxWidth: 1920
        }
        m.top.results = ImageURL(item.Id, "Primary", params)
    else
        m.top.results = invalid
    end if
end sub
