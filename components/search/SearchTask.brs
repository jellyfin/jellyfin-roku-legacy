import "pkg:/source/api/Items.brs"
import "pkg:/source/api/baserequest.brs"
import "pkg:/source/utils/config.brs"
import "pkg:/source/api/Image.brs"
import "pkg:/source/utils/deviceCapabilities.brs"

sub init()
    m.top.functionName = "search"
end sub

sub search()
    if m.top.query <> invalid and m.top.query <> ""
        m.top.results = searchMedia(m.top.query)
    end if
end sub
