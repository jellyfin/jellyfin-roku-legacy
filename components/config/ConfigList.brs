import "pkg:/source/utils/config.brs"

sub init()
    m.top.itemComponentName = "ConfigItem"

    m.top.drawFocusFeedback = True
    m.top.vertFocusAnimationStyle = "floatingFocus"

    m.top.observeField("itemSelected", "onItemSelected")

    m.top.itemSize = [750, 75]
    m.top.itemSpacing = [0, 25]

    m.top.setfocus(true)

end sub

sub setData()
    items = m.top.configItems
    data = CreateObject("roSGNode", "ContentNode")
    data.appendChildren(items)

    m.top.content = data
end sub

sub onItemSelected()
    i = m.top.itemSelected
    itemField = m.top.content.getchild(i)

    show_dialog(itemField)
end sub

function onDialogButton()
    d = m.dialog
    button_text = d.buttons[d.buttonSelected]

    if button_text = tr("OK")
        m.configField.value = d.text
        dismiss_dialog()
        return true
    else if button_text = tr("Cancel")
        dismiss_dialog()
        return true
    end if
    return false
end function


sub show_dialog(configField)
    dialog = createObject("roSGNode", "StandardKeyboardDialog")
    m.configField = configField
    dialog.title = configField.label
    dialog.buttons = [tr("OK"), tr("Cancel")]
    m.greenPalette = createObject("roSGNode", "RSGPalette")
    m.greenPalette.colors = {
        DialogBackgroundColor: "#2A2B2A"
    }
    dialog.palette = m.greenPalette

    if configField.type = "password"
        dialog.textEditBox.secureMode = true
    end if

    if configField.value <> ""
        dialog.text = configField.value
    end if

    m.top.getscene().dialog = dialog
    m.dialog = dialog

    dialog.observeField("buttonSelected", "onDialogButton")
end sub

sub dismiss_dialog()
    m.dialog.close = true
end sub
