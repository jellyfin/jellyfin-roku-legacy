sub init()
    m.content = m.top.findNode("content")

    setPalette()

    m.top.id = "OKDialog"
    m.top.height = 900
    m.top.title = "What's New?"
    m.top.buttons = [tr("OK")]

    dialogStyles = {
        "default": {
            "fontSize": 27,
            "fontUri": "font:SystemFontFile",
            "color": "#EFEFEFFF"
        },
        "author": {
            "fontSize": 27,
            "fontUri": "font:SystemFontFile",
            "color": "#00a4dcFF"
        }
    }

    whatsNewList = ParseJSON(ReadAsciiFile("pkg:/source/static/whatsNew.json"))

    for each item in whatsNewList
        textLine = m.content.CreateChild("StdDlgMultiStyleTextItem")
        textLine.drawingStyles = dialogStyles
        textLine.text = "• " + item.description + " <author>" + item.author + "</author>"
    end for

end sub

sub setPalette()
    dlgPalette = createObject("roSGNode", "RSGPalette")
    dlgPalette.colors = {
        DialogBackgroundColor: "0x262828FF",
        DialogFocusColor: "0xcececeFF",
        DialogFocusItemColor: "0x202020FF",
        DialogSecondaryTextColor: "0xf8f8f8ff",
        DialogSecondaryItemColor: "#00a4dcFF",
        DialogTextColor: "0xeeeeeeFF"
    }

    m.top.palette = dlgPalette
end sub
