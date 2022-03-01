function MarkItemFavorite(id as string)
    url = Substitute("Users/{0}/FavoriteItems/{1}", get_setting("active_user"), id)
    resp = APIRequest(url)
    return postJson(resp)
end function

function UnmarkItemFavorite(id as string)
    url = Substitute("Users/{0}/FavoriteItems/{1}", get_setting("active_user"), id)
    resp = APIRequest(url)
    resp.setRequest("DELETE")
    return getJson(resp)
end function

sub MarkItemWatched(id as string)
    date = CreateObject("roDateTime")
    dateStr = date.ToISOString()
    url = Substitute("Users/{0}/PlayedItems/{1}", get_setting("active_user"), id)
    req = APIRequest(url)
    postVoid(req, FormatJson({ "DatePlayed": dateStr }))
end sub

function UnmarkItemWatched(id as string)
    url = Substitute("Users/{0}/PlayedItems/{1}", get_setting("active_user"), id)
    resp = APIRequest(url)
    resp.setRequest("DELETE")
    return getJson(resp)
end function
