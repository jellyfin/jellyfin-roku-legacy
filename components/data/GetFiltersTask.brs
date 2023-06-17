import "pkg:/source/utils/config.brs"
import "pkg:/source/api/sdk.bs"

sub init()
    m.top.functionName = "getFiltersTask"
end sub

sub getFiltersTask()
    m.filters = api.items.GetFilters(m.top.params)
    m.top.filters = m.filters
end sub
