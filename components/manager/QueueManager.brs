sub init()
    m.queue = []
    m.queueTypes = []
    m.position = 0
end sub

'
' Clear all content from play queue
sub clear()
    m.queue = []
    m.queueTypes = []
    setPosition(0)
end sub


'
' Delete item from play queue at passed index
sub deleteAtIndex(index)
    m.queue.Delete(index)
    m.queueTypes.Delete(index)
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
' Return the types of items in current play queue
function getQueueTypes()
    return m.queueTypes
end function


'
' Return the unique types of items in current play queue
function getQueueUniqueTypes()
    itemTypes = []

    for each item in getQueueTypes()
        if not inArray(itemTypes, item)
            itemTypes.push(item)
        end if
    end for

    return itemTypes
end function


'
' Return item at end of play queue without removing
function peek()
    return m.queue.peek()
end function


'
' Play items in queue
sub playQueue()
    nextItem = getCurrentItem()
    nextItemMediaType = getItemType(nextItem)

    if not isValid(nextItemMediaType) then return

    if nextItemMediaType = "audio"
        CreateAudioPlayerView()
    else if nextItemMediaType = "video"
        CreateVideoPlayerView()
    else if nextItemMediaType = "episode"
        CreateVideoPlayerView()
    end if
end sub


'
' Remove item at end of play queue
sub pop()
    m.queue.pop()
    m.queueTypes.pop()
end sub


'
' Push new items to the play queue
sub push(newItem)
    m.queue.push(newItem)
    m.queueTypes.push(getItemType(newItem))
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
    for each item in items
        m.queueTypes.push(getItemType(item))
    end for
end sub

function getItemType(item) as string

    if isValid(item?.json?.mediatype) and item.json.mediatype <> ""
        return LCase(item.json.mediatype)
    else if isValid(item?.type) and item.type <> ""
        return LCase(item.type)
    end if

    return invalid
end function
