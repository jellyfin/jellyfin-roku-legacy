sub init()
    m.top.visible = true
    'm.top.observeField("itenRowSelected", "itemSelected")
    updateSize()
end sub

sub updateSize()
    'dimensions = m.top.getScene().currentDesignResolution()
    itemWidth = 240
    itemHeight = 300
    m.top.itemSize = [1410, itemHeight]
    m.top.rowItemSize = [itemWidth, itemHeight]
    m.top.rowItemSpacing = [24, 0]
end sub

sub setUpRows()
    m.top.content = setData()
    m.top.visible = true
end sub

function setData()
    data = CreateObject("roSGNode", "ContentNode") ' The row Node
    if m.top.itemContent = invalid then
    '    ' Return an empty node just to return something; We'll update as soon as we have data
        return data
    end if

    ' Create "Cast & Crew" Row
    row = data.createChild("ContentNode")
    row.Title = "Cast & Crew"
    for each item in m.top.itemContent.People
        img = row.createChild("ExtrasData")
        if item.PrimaryImageTag <> invalid
            posterUrl = ImageURL(item.Id, "Primary", { "Tags": item.PrimaryImageTag })
        else
            posterUrl = "pkg:/images/baseline_person_white_48dp.png"
        end if
        img.labelText = item.name
        img.subTitle = item.Type
        img.posterUrl = posterUrl
    end for
    
    ' Create a diummy row until other rows are defined
    row = data.CreateChild ("ContentNode")
    row.title = "Second Row"
    list = ["First One", "Second One"]
    for each item in list
        img = row.createChild("ExtrasData")
        img.labelText = item
        img.subTitle = "Sluggard"
        img.posterUrl = "pkg:/images/baseline_person_white_48dp.png"
    end for
    return data
end function

sub itemSelected()
    'm.top.personSelected = m.top.content.getChild(m.top.rowItemSelected(0)).m.top.getChild(m.top.rowItemSelected(1))
end sub
