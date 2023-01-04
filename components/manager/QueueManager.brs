sub init()
    m.queue = []
    m.position = 0
end sub

'
' Clear all content from play queue
sub clear()
    m.queue = []
    setPosition(0)
end sub


'
' Delete item from play queue at passed index
sub deleteAtIndex(index)
    m.queue.Delete(index)
end sub


'
' Return the number of items in the play queue
function getCount()
    return m.queue.count()
end function


'
' Return the item currently in focus from the play queue
function getCurrentItem()
    return getItemByIndex(m.position)
end function


'
' Return the item in the passed index from the play queue
function getItemByIndex(index)
    return m.queue[index]
end function


'
' Returns current playback position within the queue
function getPosition()
    return m.position
end function


'
' Move queue position back one
sub moveBack()
    m.position--
end sub


'
' Move queue position ahead one
sub moveForward()
    m.position++
end sub


'
' Return the current play queue
function getQueue()
    return m.queue
end function


'
' Return item at end of play queue without removing
function peek()
    return m.queue.peek()
end function


'
' Play items in queue
sub playQueue()
    nextItem = top()
    nextItemMediaType = invalid

    if isValid(nextItem?.json?.mediatype) and nextItem.json.mediatype <> ""
        nextItemMediaType = LCase(nextItem.json.mediatype)
    else if isValid(nextItem?.type) and nextItem.type <> ""
        nextItemMediaType = LCase(nextItem.type)
    end if

    if not isValid(nextItemMediaType) then return

    if nextItemMediaType = "audio"
        CreateAudioPlayerView()
    end if
end sub


'
' Remove item at end of play queue
sub pop()
    m.queue.pop()
end sub


'
' Push new items to the play queue
sub push(newItem)
    m.queue.push(newItem)
end sub

'
' Set the queue position
sub setPosition(newPosition)
    m.position = newPosition
end sub


'
' Return the fitst item in the play queue
function top()
    return getItemByIndex(0)
end function


'
' Replace play queue with passed array
sub set(items)
    setPosition(0)
    m.queue = items
end sub
