import "pkg:/source/utils/misc.brs"

sub init()
    m.content = m.top.findNode("content")
    m.top.observeField("contentData", "onContentDataChanged")

    m.top.observeFieldScoped("buttonSelected", "onButtonSelected")

    m.top.id = "OKDialog"
    m.top.height = 900
    m.top.title = "What's New?"
    m.top.buttons = [tr("OK")]
end sub

sub onButtonSelected()
    if m.top.buttonSelected = 0
        m.global.sceneManager.returnData = m.top.contentData.data[m.content.selectedIndex]
    end if
end sub

sub onContentDataChanged()
    i = 0
    for each item in m.top.contentData.data
        cardItem = m.content.CreateChild("StdDlgActionCardItem")
        cardItem.iconType = "radiobutton"

        if isValid(item.selected)
            m.content.selectedIndex = i
        end if

        textLine = cardItem.CreateChild("SimpleLabel")
        textLine.text = item.description
        i++
    end for
end sub
