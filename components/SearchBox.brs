sub init()
    m.top.layoutDirection = "vert"
    m.top.horizAlignment = "center"
    m.top.vertAlignment = "top"
    m.top.visible = false
    m.searchText = m.top.findNode("search_Key")
    m.searchText.textEditBox.hintText = tr("Enter Search Query")
    ' m.searchText.keyGrid.keyDefinitionUri="pkg:/components/data/CustomAddressKDF.json"
    m.searchText.textEditBox.voiceEnabled = true
    m.searchText.textEditBox.active = true
    m.searchText.ObserveField("text", "SearchMedias")
    m.searchSelect = m.top.findNode("SearchSelect")

    'set lable text
    m.label = m.top.findNode("text")
    m.label.text = tr("Search now")

end sub

sub SearchMedias()

    m.top.search_values = m.searchText.text
end sub
