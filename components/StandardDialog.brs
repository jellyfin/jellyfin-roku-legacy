sub init()
    m.content = m.top.findNode("content")
    m.top.observeField("contentData", "onContentDataChanged")

    m.top.id = "OKDialog"
    m.top.height = 900
    m.top.title = "What's New?"
    m.top.buttons = [tr("OK")]

    m.dialogStyles = {
        "default": {
            "fontSize": 27,
            "fontUri": "font:BoldSystemFontFile",
            "color": "#EFEFEFFF"
        },
        "b": {
            "fontSize": 27,
            "fontUri": "font:SystemFontFile",
            "color": "#999999"
        },
        "header": {
            "fontSize": 35,
            "fontUri": "font:SystemFontFile",
            "color": "#00a4dcFF"
        }
    }

end sub

sub onContentDataChanged()
    for each item in m.top.contentData.data
        textLine = m.content.CreateChild("StdDlgMultiStyleTextItem")
        textLine.drawingStyles = m.dialogStyles
        textLine.text = item
    end for
end sub
