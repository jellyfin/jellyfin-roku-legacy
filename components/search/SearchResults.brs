import "pkg:/source/api/Items.brs"
import "pkg:/source/api/baserequest.brs"
import "pkg:/source/utils/config.brs"
import "pkg:/source/api/Image.brs"
import "pkg:/source/utils/deviceCapabilities.brs"

sub init()
    m.top.optionsAvailable = false
    m.searchSpinner = m.top.findnode("searchSpinner")
    m.searchSelect = m.top.findnode("searchSelect")
    m.searchTask = CreateObject("roSGNode", "SearchTask")

    'set label text
    m.searchHelpText = m.top.findNode("SearchHelpText")
    m.searchHelpText.text = tr("You can search for Titles, People, Live TV Channels and more")

end sub

sub searchMedias()
    query = m.top.searchAlpha
    'if user deletes the search string hide the spinner
    if query.len() = 0
        m.searchSpinner.visible = false
    end if
    'if search task is running and user selectes another letter stop the search and load the next letter
    m.searchTask.control = "stop"
    if query <> invalid and query <> ""
        m.searchSpinner.visible = true
    end if
    m.searchTask.observeField("results", "loadResults")
    m.searchTask.query = query
    m.top.overhangTitle = tr("Search") + ": " + query
    m.searchTask.control = "RUN"

end sub

sub loadResults()
    m.searchTask.unobserveField("results")

    m.searchSpinner.visible = false
    m.searchSelect.itemdata = m.searchTask.results
    m.searchSelect.query = m.top.SearchAlpha
    m.searchHelpText.visible = false
    m.searchAlphabox = m.top.findnode("searchResults")
    m.searchAlphabox.translation = "[470, 85]"
end sub

function onKeyEvent(key as string, press as boolean) as boolean

    m.searchAlphabox = m.top.findNode("search_Key")
    if m.searchAlphabox.textEditBox.hasFocus()
        m.searchAlphabox.textEditBox.translation = "[0, -150]"
    else
        m.searchAlphabox.textEditBox.translation = "[0, 0]"
    end if

    if key = "left" and m.searchSelect.isinFocusChain()
        m.searchAlphabox.setFocus(true)
        return true
    else if key = "right"
        m.searchSelect.setFocus(true)
        return true
    end if
    return false

end function
