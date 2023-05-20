import "pkg:/source/utils/config.brs"
import "pkg:/source/roku_modules/api/api.brs"

sub init()
    m.top.functionName = "getFiltersTask"
end sub

sub getFiltersTask()
    m.filters = api_API().items.getFilters(m.top.params)
    m.top.filters = m.filters
end sub
