function get_token(user as string, password as string)
    url = "Users/AuthenticateByName?format=json"
    req = APIRequest(url)

    json = postJson(req, FormatJson({ "Username": user, "Pw": password }))

    if json = invalid then return invalid

    userdata = CreateObject("roSGNode", "UserData")
    userdata.json = json

    userdata.callFunc("setActive")
    userdata.callFunc("saveToRegistry")
    return userdata
end function

function AboutMe()
    id = get_setting("active_user")
    url = Substitute("Users/{0}", id)
    resp = APIRequest(url)
    return getJson(resp)
end function

sub SignOut(deleteSavedEntry = true as boolean)
    if get_setting("active_user") <> invalid
        unset_user_setting("token")
        unset_setting("username")
        unset_setting("password")
        if deleteSavedEntry = true
            'Also delete any credentials in the "saved servers" list
            saved = get_setting("saved_servers")
            server = get_setting("server")
            if server <> invalid
                server = LCase(server)
                savedServers = ParseJson(saved)
                newServers = { serverList: [] }
                for each item in savedServers.serverList
                    if item.baseUrl = server
                        item.username = ""
                        item.password = ""
                    end if
                    newServers.serverList.Push(item)
                end for
                set_setting("saved_servers", FormatJson(newServers))
            end if
        end if
    end if
    unset_setting("active_user")
    m.global.sceneManager.currentUser = ""
    group = m.global.sceneManager.callFunc("getActiveScene")
    group.optionsAvailable = false
end sub

function AvailableUsers()
    users = parseJson(get_setting("available_users", "[]"))
    return users
end function

sub PickUser(id as string)
    this_user = invalid
    for each user in AvailableUsers()
        if user.id = id then this_user = user
    end for
    if this_user = invalid then return
    set_setting("active_user", this_user.id)
    set_setting("server", this_user.server)
end sub

sub RemoveUser(id as string)
    user = CreateObject("roSGNode", "UserData")
    user.id = id
    user.callFunc("removeFromRegistry")

    if get_setting("active_user") = id then SignOut(false)
end sub

function ServerInfo()
    url = "System/Info/Public"
    req = APIRequest(url)

    req.setMessagePort(CreateObject("roMessagePort"))
    req.AsyncGetToString()

    ' wait 15 seconds for a server response
    resp = wait(35000, req.GetMessagePort())

    ' handle unknown errors
    if type(resp) <> "roUrlEvent"
        return { "Error": true, "ErrorMessage": "Unknown" }
    end if

    ' check for a location redirect header in the response
    headers = resp.GetResponseHeaders()
    if headers <> invalid and headers.location <> invalid

        ' only follow redirect if it the API Endpoint path is the same (/System/Info/Public)
        ' set the server to new location and try again
        if right(headers.location, 19) = "/System/Info/Public"
            set_setting("server", left(headers.location, len(headers.location) - 19))
            info = ServerInfo()
            if info.Error
                info.UpdatedUrl = left(headers.location, len(headers.location) - 19)
                info.ErrorMessage = info.ErrorMessage + " (Note: Server redirected us to " + info.UpdatedUrl + ")"
            end if
            return info
        end if
    end if

    ' handle any non 200 responses, returning the error code and message
    if resp.GetResponseCode() <> 200
        return { "Error": true, "ErrorCode": resp.GetResponseCode(), "ErrorMessage": resp.GetFailureReason() }
    end if

    ' return the parsed response string
    responseString = resp.GetString()
    if responseString <> invalid and responseString <> ""
        result = ParseJson(responseString)
        if result <> invalid
            result.Error = false
            return result
        end if
    end if

    ' otherwise return error message
    return { "Error": true, "ErrorMessage": "Does not appear to be a Jellyfin Server" }

end function

function GetPublicUsers()
    url = "Users/Public"
    resp = APIRequest(url)
    return getJson(resp)
end function

' Load and parse Display Settings from server
sub LoadUserPreferences()
    id = get_setting("active_user")
    ' Currently using client "emby", which is what website uses so we get same Display prefs as web.
    ' May want to change to specific Roku display settings
    url = Substitute("DisplayPreferences/usersettings?userId={0}&client=emby", id)
    resp = APIRequest(url)
    jsonResponse = getJson(resp)

    if jsonResponse <> invalid and jsonResponse.CustomPrefs <> invalid and jsonResponse.CustomPrefs["landing-livetv"] <> invalid
        set_user_setting("display.livetv.landing", jsonResponse.CustomPrefs["landing-livetv"])
    else
        unset_user_setting("display.livetv.landing")
    end if
end sub

sub LoadUserAbilities(user)
    ' Only have one thing we're checking now, but in the future it could be more...
    if user.Policy.EnableLiveTvManagement = true
        set_user_setting("livetv.canrecord", "true")
    else
        set_user_setting("livetv.canrecord", "false")
    end if
end sub

function initQuickConnect()
    resp = APIRequest("QuickConnect/Initiate")
    jsonResponse = getJson(resp)
    if jsonResponse = invalid
        return invalid
    end if

    if jsonResponse.Secret = invalid
        return invalid
    end if

    return jsonResponse
end function

function checkQuickConnect(secret)
    url = Substitute("QuickConnect/Connect?secret={0}", secret)
    resp = APIRequest(url)
    jsonResponse = getJson(resp)
    if jsonResponse = invalid
        return false
    end if

    if jsonResponse.Authenticated <> invalid and jsonResponse.Authenticated = true
        return true
    end if

    return false
end function

function AuthenticateViaQuickConnect(secret)
    params = {
        secret: secret
    }
    req = APIRequest("Users/AuthenticateWithQuickConnect")
    jsonResponse = postJson(req, FormatJson(params))
    if jsonResponse <> invalid and jsonResponse.AccessToken <> invalid
        userdata = CreateObject("roSGNode", "UserData")
        userdata.json = jsonResponse
        userdata.callFunc("setActive")
        userdata.callFunc("saveToRegistry")
        return true
    end if

    return false
end function
