import "pkg:/source/api/Items.brs"
import "pkg:/source/api/baserequest.brs"
import "pkg:/source/utils/config.brs"
import "pkg:/source/api/Image.brs"
import "pkg:/source/utils/deviceCapabilities.brs"

sub init()
    m.top.layoutDirection = "vert"
    m.top.horizAlignment = "center"
    m.top.vertAlignment = "top"
    m.top.visible = false
    m.searchText = m.top.findNode("search_Key")
    m.searchText.textEditBox.hintText = tr("Search")
    m.searchText.keyGrid.keyDefinitionUri = "pkg:/components/data/CustomAddressKDF.json"
    m.searchText.textEditBox.voiceEnabled = true
    m.searchText.textEditBox.active = true
    m.searchText.ObserveField("text", "searchMedias")
    m.searchSelect = m.top.findNode("searchSelect")

    'set lable text
    m.label = m.top.findNode("text")
    m.label.text = tr("Search now")

end sub

sub searchMedias()
    m.top.search_values = m.searchText.text
    if m.top.search_values.len() > 1
        m.searchText.textEditBox.leadingEllipsis = true
    else
        m.searchText.textEditBox.leadingEllipsis = false
    end if
end sub
