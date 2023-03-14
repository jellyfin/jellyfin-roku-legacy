sub init()

    m.buttons = m.top.findNode("buttons")
    m.buttons.buttons = [tr("View"), tr("Sort"), tr("Filter")]
    m.buttons.selectedIndex = 1
    m.buttons.setFocus(true)

    m.favoriteMenu = m.top.findNode("favoriteMenu")
    m.selectedFavoriteItem = m.top.findNode("selectedFavoriteItem")

    m.selectedSortIndex = 0
    m.selectedItem = 1

    m.menus = []
    m.menus.push(m.top.findNode("viewMenu"))
    m.menus.push(m.top.findNode("sortMenu"))
    m.menus.push(m.top.findNode("filterMenu"))

    m.filterOptions = m.top.findNode("filterOptions")

    m.filterMenu = m.top.findNode("filterMenu")
    m.filterMenu.observeField("itemFocused", "onFilterFocusChange")

    m.viewNames = []
    m.sortNames = []
    m.filterNames = []

    ' Animation
    m.fadeAnim = m.top.findNode("fadeAnim")
    m.fadeOutAnimOpacity = m.top.findNode("outOpacity")
    m.fadeInAnimOpacity = m.top.findNode("inOpacity")
    m.showChecklistAnimation = m.top.findNode("showChecklistAnimation")
    m.hideChecklistAnimation = m.top.findNode("hideChecklistAnimation")

    m.buttons.observeField("focusedIndex", "buttonFocusChanged")
    m.favoriteMenu.observeField("buttonSelected", "toggleFavorite")
end sub

sub showChecklist()
    if m.filterOptions.opacity = 0
        if m.showChecklistAnimation.state = "stopped"
            m.showChecklistAnimation.control = "start"
        end if
    end if
end sub

sub hideChecklist()
    if m.filterOptions.opacity = 1
        if m.hideChecklistAnimation.state = "stopped"
            m.hideChecklistAnimation.control = "start"
        end if
    end if
end sub

sub onFilterFocusChange()
    if m.filterMenu.content.getChild(m.filterMenu.itemFocused).getChildCount() > 0
        showChecklist()
    else
        hideChecklist()
    end if

    m.filterOptions.content = m.filterMenu.content.getChild(m.filterMenu.itemFocused)
    if isValid(m.filterMenu.content.getChild(m.filterMenu.itemFocused).checkedState)
        m.filterOptions.checkedState = m.filterMenu.content.getChild(m.filterMenu.itemFocused).checkedState
    else
        m.filterOptions.checkedState = []
    end if
end sub


sub optionsSet()
    '  Views Tab
    if m.top.options.views <> invalid
        viewContent = CreateObject("roSGNode", "ContentNode")
        index = 0
        selectedViewIndex = m.selectedViewIndex

        for each view in m.top.options.views
            entry = viewContent.CreateChild("ContentNode")
            entry.title = view.Title
            m.viewNames.push(view.Name)
            if (view.selected <> invalid and view.selected = true) or viewContent.Name = m.top.view
                selectedViewIndex = index
            end if
            index = index + 1
        end for
        m.menus[0].content = viewContent
        m.menus[0].checkedItem = selectedViewIndex
    end if

    ' Sort Tab
    if m.top.options.sort <> invalid
        sortContent = CreateObject("roSGNode", "ContentNode")
        index = 0
        m.selectedSortIndex = 0

        for each sortItem in m.top.options.sort
            entry = sortContent.CreateChild("ContentNode")
            entry.title = sortItem.Title
            m.sortNames.push(sortItem.Name)
            if sortItem.Selected <> invalid and sortItem.Selected = true
                m.selectedSortIndex = index
                if sortItem.Ascending <> invalid and sortItem.Ascending = false
                    m.top.sortAscending = 0
                else
                    m.top.sortAscending = 1
                end if
            end if
            index = index + 1
        end for
        m.menus[1].content = sortContent
        m.menus[1].checkedItem = m.selectedSortIndex

        if m.top.sortAscending = 1
            m.menus[1].focusedCheckedIconUri = m.global.constants.icons.ascending_black
            m.menus[1].checkedIconUri = m.global.constants.icons.ascending_white
        else
            m.menus[1].focusedCheckedIconUri = m.global.constants.icons.descending_black
            m.menus[1].checkedIconUri = m.global.constants.icons.descending_white
        end if
    end if

    ' Filter Tab
    if m.top.options.filter <> invalid
        filterContent = CreateObject("roSGNode", "ContentNode")
        index = 0
        m.selectedFilterIndex = 0

        for each filterItem in m.top.options.filter
            entry = filterContent.CreateChild("OptionNode")
            entry.title = filterItem.Title
            entry.name = filterItem.Name
            entry.delimiter = filterItem.Delimiter

            if isValid(filterItem.options)
                for each filterItemOption in filterItem.options
                    entryOption = entry.CreateChild("ContentNode")
                    entryOption.title = toString(filterItemOption)
                end for
                entry.checkedState = filterItem.checkedState
            end if

            m.filterNames.push(filterItem.Name)
            if filterItem.selected <> invalid and filterItem.selected = true
                m.selectedFilterIndex = index
            end if
            index = index + 1
        end for
        m.menus[2].content = filterContent
        m.menus[2].checkedItem = m.selectedFilterIndex
    else
        filterContent = CreateObject("roSGNode", "ContentNode")
        entry = filterContent.CreateChild("ContentNode")
        entry.title = "All"
        m.filterNames.push("All")
        m.menus[2].content = filterContent
        m.menus[2].checkedItem = 0
    end if
end sub

' Switch menu shown when button focus changes
sub buttonFocusChanged()
    if m.buttons.focusedIndex = m.selectedItem
        if m.buttons.hasFocus()
            m.buttons.setFocus(false)
            m.menus[m.selectedItem].setFocus(false)
            m.menus[m.selectedItem].visible = false
            m.favoriteMenu.setFocus(true)
        end if
    end if
    m.fadeOutAnimOpacity.fieldToInterp = m.menus[m.selectedItem].id + ".opacity"
    m.fadeInAnimOpacity.fieldToInterp = m.menus[m.buttons.focusedIndex].id + ".opacity"
    m.fadeAnim.control = "start"
    m.selectedItem = m.buttons.focusedIndex
end sub

sub toggleFavorite()
    m.favItemsTask = createObject("roSGNode", "FavoriteItemsTask")
    if m.favoriteMenu.iconUri = "pkg:/images/icons/favorite.png"
        m.favoriteMenu.iconUri = "pkg:/images/icons/favorite_selected.png"
        m.favoriteMenu.focusedIconUri = "pkg:/images/icons/favorite_selected.png"
        ' Run the task to actually favorite it via API
        m.favItemsTask.favTask = "Favorite"
        m.favItemsTask.itemId = m.selectedFavoriteItem.id
        m.favItemsTask.control = "RUN"
    else
        m.favoriteMenu.iconUri = "pkg:/images/icons/favorite.png"
        m.favoriteMenu.focusedIconUri = "pkg:/images/icons/favorite.png"
        m.favItemsTask.favTask = "Unfavorite"
        m.favItemsTask.itemId = m.selectedFavoriteItem.id
        m.favItemsTask.control = "RUN"
    end if
    ' Make sure we set the Favorite Heart color for the appropriate child
    setHeartColor("#cc3333")
end sub

sub setHeartColor(color as string)
    try
        for i = 0 to 6
            node = m.favoriteMenu.getChild(i)
            if node <> invalid and node.uri <> invalid and node.uri = "pkg:/images/icons/favorite_selected.png"
                m.favoriteMenu.getChild(i).blendColor = color
            end if
        end for
    catch e
        print e.number, e.message
    end try
end sub

sub saveFavoriteItemSelected(msg)
    data = msg.GetData()
    m.selectedFavoriteItem = data
    ' Favorite button
    if m.selectedFavoriteItem <> invalid
        if m.selectedFavoriteItem.favorite = true
            m.favoriteMenu.iconUri = "pkg:/images/icons/favorite_selected.png"
            m.favoriteMenu.focusedIconUri = "pkg:/images/icons/favorite_selected.png"
            ' Make sure we set the Favorite Heart color for the appropriate child
            setHeartColor("#cc3333")
        else
            m.favoriteMenu.iconUri = "pkg:/images/icons/favorite.png"
            m.favoriteMenu.focusedIconUri = "pkg:/images/icons/favorite.png"
            ' Make sure we set the Favorite Heart color for the appropriate child
            setHeartColor("#cc3333")
        end if
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean

    if key = "down" or (key = "OK" and m.buttons.hasFocus())
        m.buttons.setFocus(false)
        m.menus[m.selectedItem].setFocus(true)
        m.menus[m.selectedItem].drawFocusFeedback = true

        'If user presses down from button menu, focus first item.  If OK, focus checked item
        if key = "down"
            m.menus[m.selectedItem].jumpToItem = 0
        else
            m.menus[m.selectedItem].jumpToItem = m.menus[m.selectedItem].itemSelected
        end if

        return true
    else if key = "right"
        if m.menus[m.selectedItem].isInFocusChain()
            ' Handle Filter screen
            if m.selectedItem = 2
                ' Selected filter has options, move cursor to it
                if m.filterMenu.content.getChild(m.filterMenu.itemFocused).getChildCount() > 0
                    m.menus[m.selectedItem].setFocus(false)
                    m.filterOptions.setFocus(true)
                    return true
                end if
            end if
        end if
    else if key = "left"
        if m.favoriteMenu.hasFocus()
            m.favoriteMenu.setFocus(false)
            m.menus[m.selectedItem].visible = true
            m.buttons.setFocus(true)
        end if

        ' User wants to escape filter options
        if m.filterOptions.isInFocusChain()
            m.filterOptions.setFocus(false)
            m.menus[m.selectedItem].setFocus(true)
            return true
        end if
    else if key = "OK"
        if m.menus[m.selectedItem].isInFocusChain()
            ' Handle View Screen
            if m.selectedItem = 0
                m.selectedViewIndex = m.menus[0].itemSelected
                m.top.view = m.viewNames[m.selectedViewIndex]
            end if

            ' Handle Sort screen
            if m.selectedItem = 1
                if m.menus[1].itemSelected <> m.selectedSortIndex
                    m.menus[1].focusedCheckedIconUri = m.global.constants.icons.ascending_black
                    m.menus[1].checkedIconUri = m.global.constants.icons.ascending_white

                    m.selectedSortIndex = m.menus[1].itemSelected
                    m.top.sortAscending = true
                    m.top.sortField = m.sortNames[m.selectedSortIndex]
                else

                    if m.top.sortAscending = true
                        m.top.sortAscending = false
                        m.menus[1].focusedCheckedIconUri = m.global.constants.icons.descending_black
                        m.menus[1].checkedIconUri = m.global.constants.icons.descending_white
                    else
                        m.top.sortAscending = true
                        m.menus[1].focusedCheckedIconUri = m.global.constants.icons.ascending_black
                        m.menus[1].checkedIconUri = m.global.constants.icons.ascending_white
                    end if
                end if
            end if

            ' Handle Filter screen
            if m.selectedItem = 2
                ' If filter has no options, select it
                if m.filterMenu.content.getChild(m.filterMenu.itemFocused).getChildCount() = 0
                    m.menus[2].checkedItem = m.menus[2].itemSelected
                    m.selectedFilterIndex = m.menus[2].itemSelected
                    m.top.filter = m.filterNames[m.selectedFilterIndex]
                    m.top.filterOptions = {}
                    return true
                end if

                ' Selected filter has options, move cursor to it
                m.filterOptions.setFocus(true)
                m.menus[m.selectedItem].setFocus(false)
                return true
            end if
        end if

        ' User pressed OK from inside the filter's options
        if m.filterOptions.isInFocusChain()
            selectedOptions = []
            for i = 0 to m.filterOptions.checkedState.count() - 1
                if m.filterOptions.checkedState[i]
                    selectedValue = toString(m.filterOptions.content.getChild(i).title)
                    selectedOptions.push(selectedValue)
                end if
            end for

            if selectedOptions.Count() > 0
                m.menus[2].checkedItem = m.menus[2].itemFocused
                m.selectedFilterIndex = m.menus[2].itemFocused
                m.top.filter = m.filterMenu.content.getChild(m.filterMenu.itemFocused).Name

                newFilter = {}
                newFilter[m.top.filter] = selectedOptions.join(m.filterMenu.content.getChild(m.filterMenu.itemFocused).delimiter)
                m.top.filterOptions = newFilter
            else
                m.menus[2].checkedItem = 0
                m.selectedFilterIndex = 0
                m.top.filter = m.filterNames[0]
                m.top.filterOptions = {}
            end if

            m.filterMenu.content.getChild(m.filterMenu.itemFocused).checkedState = m.filterOptions.checkedState

            return true
        end if
        return true
    else if key = "back" or key = "up"
        if key = "back" then hideChecklist()

        m.menus[2].visible = true ' Show Filter contents in case hidden by favorite button
        if m.menus[m.selectedItem].isInFocusChain()
            m.buttons.setFocus(true)
            m.menus[m.selectedItem].drawFocusFeedback = false
            return true
        end if
    else if key = "options"
        hideChecklist()
        m.menus[2].visible = true ' Show Filter contents in case hidden by favorite button
        m.menus[m.selectedItem].drawFocusFeedback = false
        return false
    end if

    return false

end function
