sub init()

    m.top.overhangTitle = tr("Settings")
    m.top.optionsAvailable = false

    m.userLocation = []

    m.settingsMenu = m.top.findNode("settingsMenu")
    m.settingDetail = m.top.findNode("settingDetail")
    m.settingDesc = m.top.findNode("settingDesc")
    m.settingTitle = m.top.findNode("settingTitle")
    m.path = m.top.findNode("path")

    m.boolSetting = m.top.findNode("boolSetting")

    m.settingsMenu.setFocus(true)
    m.settingsMenu.observeField("itemFocused", "settingFocused")
    m.settingsMenu.observeField("itemSelected", "settingSelected")

    m.boolSetting.observeField("checkedItem", "boolSettingChanged")

    ' Load Configuration Tree
    m.configTree = GetConfigTree()
    LoadMenu({ children: m.configTree })
end sub


sub LoadMenu(configSection)

    if configSection.children = invalid
        ' Load parent menu
        m.userLocation.pop()
        configSection = m.userLocation.peek()
    else
        if m.userLocation.Count() > 0 then m.userLocation.peek().selectedIndex = m.settingsMenu.itemFocused
        m.userLocation.push(configSection)
    end if

    result = CreateObject("roSGNode", "ContentNode")

    for each item in configSection.children
        listItem = result.CreateChild("ContentNode")
        listItem.title = tr(item.title)
        listItem.Description = tr(item.description)
        listItem.id = item.id
    end for

    m.settingsMenu.content = result

    if configSection.selectedIndex <> invalid and configSection.selectedIndex > -1
        m.settingsMenu.jumpToItem = configSection.selectedIndex
    end if

    ' Set Path display
    m.path.text = ""
    for each level in m.userLocation
        if level.title <> invalid then m.path.text += " / " + tr(level.title)
    end for
end sub



sub settingFocused()

    selectedSetting = m.userLocation.peek().children[m.settingsMenu.itemFocused]
    m.settingDesc.text = tr(selectedSetting.Description)
    m.settingTitle.text = tr(selectedSetting.Title)

    ' Hide Settings
    m.boolSetting.visible = false

    if selectedSetting.type = invalid
        return
    else if selectedSetting.type = "bool"

        m.boolSetting.visible = true

        if get_user_setting(selectedSetting.settingName) = "true"
            m.boolSetting.checkedItem = 1
        else
            m.boolSetting.checkedItem = 0
        end if
    else
        print "Unknown setting type " + selectedSetting.type
    end if

end sub


sub settingSelected()

    selectedItem = m.userLocation.peek().children[m.settingsMenu.itemFocused]


    if selectedItem.type <> invalid ' Show setting
        if selectedItem.type = "bool"
            m.boolSetting.setFocus(true)
        end if
    else if selectedItem.children <> invalid and selectedItem.children.Count() > 0 ' Show sub menu
        LoadMenu(selectedItem)
        m.settingsMenu.setFocus(true)
    else
        return
    end if

    m.settingDesc.text = m.settingsMenu.content.GetChild(m.settingsMenu.itemFocused).Description

end sub


sub boolSettingChanged()

    if m.boolSetting.focusedChild = invalid then return
    selectedSetting = m.userLocation.peek().children[m.settingsMenu.itemFocused]

    if m.boolSetting.checkedItem
        set_user_setting(selectedSetting.settingName, "true")
    else
        set_user_setting(selectedSetting.settingName, "false")
    end if

end sub


function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if (key = "back" or key = "left") and m.settingsMenu.focusedChild <> invalid and m.userLocation.Count() > 1
        LoadMenu({})
        return true
    else if (key = "back" or key = "left") and m.settingDetail.focusedChild <> invalid
        m.settingsMenu.setFocus(true)
        return true
    end if

    if key = "right"
        settingSelected()
    end if

    return false
end function