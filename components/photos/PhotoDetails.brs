import "pkg:/source/utils/misc.brs"
import "pkg:/source/utils/config.brs"

sub init()
    m.top.optionsAvailable = true
    m.top.overhangVisible = false
    m.slideshowTimer = m.top.findNode("slideshowTimer")
    m.slideshowTimer.observeField("fire", "nextSlide")
    m.status = m.top.findNode("status")
    m.textBackground = m.top.findNode("background")
    m.statusTimer = m.top.findNode("statusTimer")
    m.statusTimer.observeField("fire", "statusUpdate")
    m.slideshow = get_user_setting("photos.slideshow")
    m.random = get_user_setting("photos.random")

    m.showStatusAnimation = m.top.findNode("showStatusAnimation")
    m.hideStatusAnimation = m.top.findNode("hideStatusAnimation")

    itemContentChanged()
end sub

sub itemContentChanged()
    if isValidToContinue(m.top.itemIndex)
        m.LoadLibrariesTask = createObject("roSGNode", "LoadPhotoTask")
        itemContent = m.top.items.content.getChild(m.top.itemIndex)
        m.LoadLibrariesTask.itemContent = itemContent
        m.LoadLibrariesTask.observeField("results", "onPhotoLoaded")
        m.LoadLibrariesTask.control = "RUN"
    end if
end sub

sub onPhotoLoaded()
    if m.LoadLibrariesTask.results <> invalid
        photo = m.top.findNode("photo")
        photo.uri = m.LoadLibrariesTask.results

        if m.slideshow = "true" or m.random = "true"
            ' user has requested either a slideshow or random...
            m.slideshowTimer.control = "start"
        end if
    else
        'Show user error here (for example if it's not a supported image type)
        message_dialog("This image type is not supported.")
    end if
end sub

sub nextSlide()
    m.slideshowTimer.control = "stop"

    if m.slideshow = "true"
        if isValidToContinue(m.top.itemIndex + 1)
            m.top.itemIndex++
            m.slideshowTimer.control = "start"
        end if
    else if m.random = "true"
        index = rnd(m.top.items.content.getChildCount() - 1)
        if isValidToContinue(index)
            m.top.itemIndex = index
            m.slideshowTimer.control = "start"
        end if
    end if
end sub

sub statusUpdate()
    m.statusTimer.control = "stop"
    m.hideStatusAnimation.control = "start"
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "right"
        if isValidToContinue(m.top.itemIndex + 1)
            m.slideshowTimer.control = "stop"
            m.top.itemIndex++
        end if
        return true
    end if

    if key = "left"
        if isValidToContinue(m.top.itemIndex - 1)
            m.slideshowTimer.control = "stop"
            m.top.itemIndex--
        end if
        return true
    end if

    if key = "play"
        if m.slideshowTimer.control = "start"
            ' stop the slideshow if the user hits "pause"
            m.slideshowTimer.control = "stop"
            m.status.text = tr("Slideshow Paused")
            if m.textBackground.opacity = 0
                m.showStatusAnimation.control = "start"
            end if
            m.statusTimer.control = "start"
        else
            ' start the slideshow if the user hits "play"
            m.status.text = tr("Slideshow Resumed")
            if m.textBackground.opacity = 0
                m.showStatusAnimation.control = "start"
            end if
            m.slideshow = "true"
            m.statusTimer.control = "start"
            m.slideshowTimer.control = "start"
        end if
        return true
    end if

    if key = "options"
        ' Options (random etc) is done on itemGrid
        return true
    end if

    return false
end function

function isValidToContinue(index as integer)
    if isValid(m.top.items) and isValid(m.top.items.content)
        if index >= 0 and index < m.top.items.content.getChildCount()
            return true
        end if
    end if

    return false
end function
