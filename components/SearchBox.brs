sub init()
    m.top.layoutDirection = "vert"
    m.top.horizAlignment = "center"
    m.top.vertAlignment = "top"
    m.top.visible = false
    m.searchText = m.top.findNode("search_Key")
    m.searchText.ObserveField("text", "SearchMedias")
    m.searchSelect = m.top.findNode("SearchSelect")

end sub

sub SearchMedias()

    m.top.search_values = m.searchText.text
end sub
