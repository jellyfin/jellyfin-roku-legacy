function loadExtras(extrasList as object, pplData as object) as object
    rowNode = CreateObject("roSGNode", "ContentNode")
    
    rowNode.title = tr(rowTitle)
    ' We may need to move this out into a Task
    for each person in pplData
    '    url = Substitute("Users/{0}/Items/{1}", get_setting("active_user"), person.id)
    '       resp = APIRequest(url)
    '       data = getJson(resp)
        item = rowNode.createChild("ExtrasItem")
        if person.PrimaryImageTag <> invalid
            posterUrl = ImageURL(person.Id, "Primary", { "Tags": person.PrimaryImageTag })
        else
            posterUrl = "pkg:/images/baseline_person_white_48dp.png"
        end if
        item.itemContent = { Name: person.Name, Role: person.Type, posterUrl: posterUrl }
    end for

    return rowNode
end function
