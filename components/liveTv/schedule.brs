sub init()
    m.EPGLaunchCompleteSignaled = false
    m.scheduleGrid = m.top.findNode("scheduleGrid")
    m.detailsPane = m.top.findNode("detailsPane")

    m.detailsPane.observeField("watchSelectedChannel", "onWatchChannelSelected")
    m.detailsPane.observeField("recordSelectedChannel", "onRecordChannelSelected")
    m.detailsPane.observeField("recordSeriesSelectedChannel", "onRecordSeriesChannelSelected")
    m.gridStartDate = CreateObject("roDateTime")
    m.scheduleGrid.contentStartTime = m.gridStartDate.AsSeconds() - 1800
    m.gridEndDate = createObject("roDateTime")
    m.gridEndDate.FromSeconds(m.gridStartDate.AsSeconds() + (24 * 60 * 60))

    m.scheduleGrid.observeField("programFocused", "onProgramFocused")
    m.scheduleGrid.observeField("programSelected", "onProgramSelected")
    m.scheduleGrid.observeField("leftEdgeTargetTime", "onGridScrolled")
    m.scheduleGrid.channelInfoWidth = 350

    m.gridMoveAnimation = m.top.findNode("gridMoveAnimation")
    m.gridMoveAnimationPosition = m.top.findNode("gridMoveAnimationPosition")

    m.gridData = createObject("roSGNode", "ContentNode")

    m.LoadChannelsTask = createObject("roSGNode", "LoadChannelsTask")
    m.LoadChannelsTask.observeField("channels", "onChannelsLoaded")
    m.LoadChannelsTask.control = "RUN"

    m.top.lastFocus = m.scheduleGrid

    m.channelIndex = {}

    m.spinner = m.top.findNode("spinner")

    'Set initial channels loaded int - TODO create user settings to control the limi
    m.top.channelsLoaded = m.LoadChannelsTask.limit

end sub

sub channelFilterSet()
    'm.scheduleGrid.jumpToChannel = 0
    if m.top.filter <> invalid and m.LoadChannelsTask.filter <> m.top.filter
        if m.LoadChannelsTask.state = "run" then m.LoadChannelsTask.control = "stop"

        m.LoadChannelsTask.filter = m.top.filter
        m.LoadChannelsTask.control = "RUN"
    end if

end sub

'Voice Search set
sub channelsearchTermSet()
    'm.scheduleGrid.jumpToChannel = 0
    if m.top.searchTerm <> invalid and m.LoadChannelsTask.searchTerm <> m.top.searchTerm
        if m.LoadChannelsTask.state = "run" then m.LoadChannelsTask.control = "stop"

        m.LoadChannelsTask.searchTerm = m.top.searchTerm
        m.spinner.visible = true
        m.LoadChannelsTask.control = "RUN"
    end if
end sub

' Initial list of channels loaded
sub onChannelsLoaded()
    m.spinner.visible = true
    counter = m.top.counter
    m.channelIdList = m.top.channelIdList
    'if search returns channels
    if m.LoadChannelsTask.channels.count() > 0
        for each item in m.LoadChannelsTask.channels
            m.gridData.appendChild(item)
            counter = counter + 1
            m.channelIndex[item.Id] = counter
            m.channelIdList = m.channelIdList + item.Id + ","
        end for
        m.scheduleGrid.content = m.gridData

        m.LoadScheduleTask = createObject("roSGNode", "LoadScheduleTask")
        m.LoadScheduleTask.observeField("schedule", "onScheduleLoaded")

        m.LoadScheduleTask.startTime = m.gridStartDate.ToISOString()
        m.LoadScheduleTask.endTime = m.gridEndDate.ToISOString()
        m.LoadScheduleTask.channelIds = m.channelIdList
        m.LoadScheduleTask.control = "RUN"

        m.LoadProgramDetailsTask = createObject("roSGNode", "LoadProgramDetailsTask")
        m.LoadProgramDetailsTask.observeField("programDetails", "onProgramDetailsLoaded")

        m.scheduleGrid.setFocus(true)
        if m.EPGLaunchCompleteSignaled = false
            m.top.signalBeacon("EPGLaunchComplete") ' Required Roku Performance monitoring
            m.EPGLaunchCompleteSignaled = true
        end if
        'm.LoadChannelsTask.channels = m.LoadChannelsTask.channels
        'm.top.channelIdList = m.channelIdList
    end if
    m.LoadChannelsTask.channels = []
    'keep focus on current channel while loading the next set of channels
    m.schedulegrid.jumpToChannel = m.detailsPane.currentChannelFocused
    m.spinner.visible = false
end sub

' When LoadScheduleTask completes (initial or more data) and we have a schedule to display
sub onScheduleLoaded()
    ' make sure we actually have a schedule (i.e. filter by favorites, but no channels have been favorited)
    if m.scheduleGrid.content.GetChildCount() <= 0
        return
    end if

    for each item in m.LoadScheduleTask.schedule

        channel = m.scheduleGrid.content.GetChild(m.channelIndex[item.ChannelId])
        if channel.PosterUrl <> ""
            item.channelLogoUri = channel.PosterUrl
        end if
        if channel.Title <> ""
            item.channelName = channel.Title
        end if

        channel.appendChild(item)
    end for

    m.scheduleGrid.showLoadingDataFeedback = false
    m.scheduleGrid.setFocus(true)
    m.LoadScheduleTask.schedule = []
    m.spinner.visible = false
end sub

sub onProgramFocused()
    m.top.watchChannel = invalid

    ' Make sure we have channels (i.e. filter set to favorite yet there are none)
    if m.scheduleGrid.content.getChildCount() <= 0
        channel = invalid
    else
        channel = m.scheduleGrid.content.GetChild(m.scheduleGrid.programFocusedDetails.focusChannelIndex)
    end if

    m.detailsPane.channel = channel
    m.detailsPane.currentChannelFocused = m.scheduleGrid.channelFocused
    m.top.focusedChannel = channel
    ' Exit if Channels not yet loaded

    if channel = invalid or channel.getChildCount() = 0

        m.detailsPane.programDetails = invalid
        return
    end if

    m.prog = channel.GetChild(m.scheduleGrid.programFocusedDetails.focusIndex)


    if m.prog <> invalid and m.prog.fullyLoaded = false
        m.LoadProgramDetailsTask.programId = m.prog.Id
        m.LoadProgramDetailsTask.channelIndex = m.scheduleGrid.programFocusedDetails.focusChannelIndex
        m.LoadProgramDetailsTask.programIndex = m.scheduleGrid.programFocusedDetails.focusIndex
        m.LoadProgramDetailsTask.control = "RUN"
    end if

    m.detailsPane.programDetails = m.prog

end sub

' Update the Program Details with full information
sub onProgramDetailsLoaded()
    if m.LoadProgramDetailsTask.programDetails = invalid then return
    channel = m.scheduleGrid.content.GetChild(m.LoadProgramDetailsTask.programDetails.channelIndex)

    ' If TV Show does not have its own image, use the channel logo
    if m.LoadProgramDetailsTask.programDetails.PosterUrl = invalid or m.LoadProgramDetailsTask.programDetails.PosterUrl = ""
        m.LoadProgramDetailsTask.programDetails.PosterUrl = channel.PosterUrl
    end if

    channel.ReplaceChild(m.LoadProgramDetailsTask.programDetails, m.LoadProgramDetailsTask.programDetails.programIndex)
    m.LoadProgramDetailsTask.programDetails = invalid
    m.scheduleGrid.showLoadingDataFeedback = false
end sub

sub advanceGuide()
    startIdex = m.LoadChannelsTask.startIndex
    'Load more Channels when grid is scrolled
    'if focus comes within 5 rows of the end load more channels
    print "Focused = ", m.top.channelChanged
    if m.top.channelChanged > (m.top.channelsLoaded - 6)
        'add loaded channels count to advance guide
        m.top.channelsLoaded = m.top.channelsLoaded + m.LoadChannelsTask.limit
        'advance start index to get new channels
        startIdex = startIdex + m.top.channelsLoaded
        'update satrt index in loaded channels task
        m.LoadChannelsTask.startIndex = startIdex
        ' if task is running stop and load more
        m.top.counter = m.top.channelsLoaded - 11
        'm.top.currentChannelFocused = m.scheduleGrid.channelFocused
        m.LoadChannelsTask.control = "RUN"
        print "********   Loaded Channels = " m.top.channelsLoaded
    end if
end sub

sub onProgramSelected()
    ' If there is no program data - view the channel
    if m.detailsPane.programDetails = invalid
        m.top.watchChannel = m.scheduleGrid.content.GetChild(m.scheduleGrid.programFocusedDetails.focusChannelIndex)
        return
    end if

    ' Move Grid Down
    focusProgramDetails(true)
end sub

' Move the TV Guide Grid down or up depending whether details are selected
sub focusProgramDetails(setFocused)

    h = m.detailsPane.height
    if h < 400 then h = 400
    h = h + 160 + 80

    if setFocused = true
        m.gridMoveAnimationPosition.keyValue = [[0, 600], [0, h]]
        m.detailsPane.setFocus(true)
        m.detailsPane.hasFocus = true
        m.top.lastFocus = m.detailsPane
    else
        m.detailsPane.hasFocus = false
        m.gridMoveAnimationPosition.keyValue = [[0, h], [0, 600]]
        m.scheduleGrid.setFocus(true)
        m.top.lastFocus = m.scheduleGrid
    end if

    m.gridMoveAnimation.control = "start"
end sub

' Handle user selecting "Watch Channel" from Program Details
sub onWatchChannelSelected()

    if m.detailsPane.watchSelectedChannel = false then return

    ' Set focus back to grid before showing channel, to ensure grid has focus when we return
    focusProgramDetails(false)

    m.top.watchChannel = m.detailsPane.channel
end sub

' As user scrolls grid, check if more data requries to be loaded
sub onGridScrolled()

    ' If we're within 12 hours of end of grid, load next 24hrs of data
    if m.scheduleGrid.leftEdgeTargetTime + (12 * 60 * 60) > m.gridEndDate.AsSeconds()

        ' Ensure the task is not already (still) running,
        if m.LoadScheduleTask.state <> "run"
            m.LoadScheduleTask.startTime = m.gridEndDate.ToISOString()
            m.gridEndDate.FromSeconds(m.gridEndDate.AsSeconds() + (24 * 60 * 60))
            m.LoadScheduleTask.endTime = m.gridEndDate.ToISOString()
            m.LoadScheduleTask.control = "RUN"
        end if
    end if

end sub

' Handle user selecting "Record Channel" from Program Details
sub onRecordChannelSelected()
    if m.detailsPane.recordSelectedChannel = false then return

    ' Set focus back to grid before showing channel, to ensure grid has focus when we return
    focusProgramDetails(false)

    m.scheduleGrid.showLoadingDataFeedback = true

    m.RecordProgramTask = createObject("roSGNode", "RecordProgramTask")
    m.RecordProgramTask.programDetails = m.detailsPane.programDetails
    m.RecordProgramTask.recordSeries = false
    m.RecordProgramTask.observeField("recordOperationDone", "onRecordOperationDone")
    m.RecordProgramTask.control = "RUN"
end sub

' Handle user selecting "Record Series" from Program Details
sub onRecordSeriesChannelSelected()
    if m.detailsPane.recordSeriesSelectedChannel = false then return

    ' Set focus back to grid before showing channel, to ensure grid has focus when we return
    focusProgramDetails(false)

    m.scheduleGrid.showLoadingDataFeedback = true

    m.RecordProgramTask = createObject("roSGNode", "RecordProgramTask")
    m.RecordProgramTask.programDetails = m.detailsPane.programDetails
    m.RecordProgramTask.recordSeries = true
    m.RecordProgramTask.observeField("recordOperationDone", "onRecordOperationDone")
    m.RecordProgramTask.control = "RUN"
end sub

sub onRecordOperationDone()
    if m.RecordProgramTask.recordSeries = true and m.LoadScheduleTask.state <> "run"
        m.LoadScheduleTask.control = "RUN"
    else
        ' This reloads just the details for the currently selected program, so that we don't have to
        ' reload the entire grid...
        channel = m.scheduleGrid.content.GetChild(m.scheduleGrid.programFocusedDetails.focusChannelIndex)
        prog = channel.GetChild(m.scheduleGrid.programFocusedDetails.focusIndex)
        m.LoadProgramDetailsTask.programId = prog.Id
        m.LoadProgramDetailsTask.channelIndex = m.scheduleGrid.programFocusedDetails.focusChannelIndex
        m.LoadProgramDetailsTask.programIndex = m.scheduleGrid.programFocusedDetails.focusIndex
        m.LoadProgramDetailsTask.control = "RUN"
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    detailsGrp = m.top.findNode("detailsPane")
    gridGrp = m.top.findNode("scheduleGrid")

    if key = "back" and detailsGrp.isInFocusChain()
        focusProgramDetails(false)
        detailsGrp.setFocus(false)
        gridGrp.setFocus(true)
        return true
    else if key = "back"
        m.LoadChannelsTask.control = "stop"
        m.global.sceneManager.callFunc("popScene")
        return true
    end if
    if key = "down"
        print "Key down"
        return true
    end if

    return false
end function
