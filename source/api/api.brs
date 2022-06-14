function API()
    instance = {}

    instance["auth"] = authActions()
    instance["branding"] = brandingActions()
    instance["system"] = systemActions()
    instance["users"] = usersActions()

    return instance
end function

function authActions()
    instance = {}

    ' Get all keys.
    instance.getkeys = function()
        req = _APIRequest("/auth/keys")
        return _getJson(req)
    end function

    ' Create a new api key.
    instance.postkeys = function(params = {} as object)
        req = _APIRequest("/auth/keys", params)
        return _postVoid(req)
    end function

    ' Remove an api key.
    instance.deletekeys = function(key as string)
        req = _APIRequest(Substitute("/auth/keys/{0}", key))
        return _deleteVoid(req)
    end function

    return instance
end function

function systemActions()
    instance = {}

    ' Gets activity log entries.
    instance.getactivitylogentries = function(params = {} as object)
        req = _APIRequest("/system/activitylog/entries", params)
        return _getJson(req)
    end function

    ' Gets information about the request endpoint.
    instance.getendpoint = function()
        req = _APIRequest("/system/endpoint")
        return _getJson(req)
    end function

    ' Gets information about the server.
    instance.getinfo = function()
        req = _APIRequest("/system/info")
        return _getJson(req)
    end function

    ' Gets public information about the server.
    instance.getpublicinfo = function()
        req = _APIRequest("/system/info/public")
        return _getJson(req)
    end function

    ' Gets a list of available server log files.
    instance.getlogs = function()
        req = _APIRequest("/system/logs")
        return _getJson(req)
    end function

    ' Gets a log file.
    instance.getlog = function(params = {} as object)
        req = _APIRequest("/system/logs/log", params)
        return _getString(req)
    end function

    ' Pings the system.
    instance.getping = function()
        req = _APIRequest("/system/ping")
        return _getString(req)
    end function

    ' Pings the system.
    instance.postping = function()
        req = _APIRequest("/system/ping")
        return _postString(req)
    end function

    ' Restarts the application.
    instance.restart = function()
        req = _APIRequest("/system/restart")
        return _postVoid(req)
    end function

    ' Shuts down the application.
    instance.shutdown = function()
        req = _APIRequest("/system/shutdown")
        return _postVoid(req)
    end function

    return instance
end function

function brandingActions()
    instance = {}

    ' Get user's splashscreen image
    instance.getsplashscreen = function(params = {} as object)
        return _buildURL("/branding/splashscreen", params)
    end function

    ' Gets branding configuration.
    instance.getconfiguration = function()
        req = _APIRequest("/branding/configuration")
        return _getJson(req)
    end function

    ' Gets branding css.
    instance.getcss = function()
        req = _APIRequest("/branding/css")
        return _getJson(req)
    end function

    return instance
end function

function usersActions()
    instance = {}

    ' Gets a list of users.
    ' If id is passed, gets a user by Id.
    instance.get = function(id = "")
        url = "/users"
        if id <> ""
            url = url + "/" + id
        end if
        req = _APIRequest(url)
        return _getJson(req)
    end function

    ' Gets the user based on auth token.
    instance.getme = function()
        req = _APIRequest("/users/me")
        return _getJson(req)
    end function

    ' Gets a list of publicly visible users for display on a login screen.
    instance.getpublic = function()
        resp = _APIRequest("/users/public")
        return _getJson(resp)
    end function

    ' Creates a user.
    instance.postnew = function(body = {} as object)
        req = _APIRequest("/users/new")
        req.SetRequest("POST")
        return _postJson(req, FormatJson(body))
    end function

    ' Deletes a user.
    instance.delete = function(id)
        req = _APIRequest(Substitute("/users/{0}", id))
        return _deleteVoid(req)
    end function

    ' Updates a user.
    instance.update = function(id, body = {} as object)
        req = _APIRequest(Substitute("/users/{0}", id))
        return _postVoid(req, FormatJson(body))
    end function

    ' Updates a user configuration.
    instance.updateconfiguration = function(id, body = {} as object)
        req = _APIRequest(Substitute("/users/{0}/configuration", id))
        return _postVoid(req, FormatJson(body))
    end function

    ' Updates a user's easy password.
    instance.updateeasypassword = function(id, body = {} as object)
        req = _APIRequest(Substitute("/users/{0}/easypassword", id))
        return _postVoid(req, FormatJson(body))
    end function

    ' Updates a user's password.
    instance.updatepassword = function(id, body = {} as object)
        req = _APIRequest(Substitute("/users/{0}/password", id))
        return _postVoid(req, FormatJson(body))
    end function

    ' Updates a user's policy.
    instance.updatepolicy = function(id, body = {} as object)
        req = _APIRequest(Substitute("/users/{0}/policy", id))
        return _postVoid(req, FormatJson(body))
    end function

    ' Authenticates a user.
    instance.authenticatebyname = function(body = {} as object)
        req = _APIRequest("users/authenticatebyname")
        json = _postJson(req, FormatJson(body))
        return json
    end function

    ' Authenticates a user with quick connect.
    instance.authenticatewithquickconnect = function(body = {} as object)
        throw "System.NotImplementedException: The function is not implemented."
        return false
    end function

    ' Initiates the forgot password process for a local user.
    instance.forgotpassword = function(body = {} as object)
        req = _APIRequest("users/forgotpassword")
        json = _postJson(req, FormatJson(body))
        return json
    end function

    ' Redeems a forgot password pin.
    instance.forgotpasswordpin = function(body = {} as object)
        req = _APIRequest("users/forgotpassword/pin")
        json = _postJson(req, FormatJson(body))
        return json
    end function

    return instance
end function

' API Helper Functions
' -------------------------

function _APIRequest(url as string, params = {} as object)
    req = createObject("roUrlTransfer")
    req.setCertificatesFile("common:/certs/ca-bundle.crt")

    full_url = _buildURL(url, params)
    req.setUrl(full_url)
    req = _authorize_request(req)

    return req
end function

function _buildURL(path as string, params = {} as object) as string

    ' Add intial '/' if path does not start with one
    if path.Left(1) = "/"
        full_url = _get_url() + path
    else
        full_url = _get_url() + "/" + path
    end if

    if params.count() > 0
        full_url = full_url + "?" + _buildParams(params)
    end if

    return full_url
end function

' Take an object of parameters and construct the URL query
function _buildParams(params = {} as object) as string
    req = createObject("roUrlTransfer") ' Just so we can use it for escape

    param_array = []
    for each field in params.items()
        item = ""
        if type(field.value) = "String" or type(field.value) = "roString"
            item = field.key + "=" + req.escape(field.value.trim())
        else if type(field.value) = "roInteger" or type(field.value) = "roInt"
            item = field.key + "=" + stri(field.value).trim()
        else if type(field.value) = "roFloat"
            item = field.key + "=" + stri(int(field.value)).trim()
        else if type(field.value) = "LongInteger"
            item = field.key + "=" + field.value.toStr().trim()
        else if type(field.value) = "roArray"
            ' TODO handle array params
        else if type(field.value) = "roBoolean"
            if field.value
                item = field.key + "=true"
            else
                item = field.key + "=false"
            end if
        else if field.value = invalid
            item = field.key + "=null"
        else if field <> invalid
            print "Unhandled param type: " + type(field.value)
            item = field.key + "=" + req.escape(field.value)
        end if

        if item <> "" then param_array.push(item)
    end for

    return param_array.join("&")
end function

function _get_url()
    base = get_setting("server")
    if base.right(1) = "/"
        base = base.left(base.len() - 1)
    end if

    ' append http:// to the start if not specified
    if base.left(7) <> "http://" and base.left(8) <> "https://"
        base = "http://" + base
    end if

    return base

end function

function _authorize_request(request)
    devinfo = CreateObject("roDeviceInfo")
    appinfo = CreateObject("roAppInfo")

    auth = "MediaBrowser"

    client = "Jellyfin Roku"
    auth = auth + " Client=" + Chr(34) + client + Chr(34)

    device = devinfo.getModelDisplayName()
    friendly = devinfo.getFriendlyName()
    ' remove special characters
    regex = CreateObject("roRegex", "[^a-zA-Z0-9\ \-\_]", "")
    friendly = regex.ReplaceAll(friendly, "")
    auth = auth + ", Device=" + Chr(34) + device + " (" + friendly + ")" + Chr(34)

    device_id = devinfo.getChannelClientID()
    if get_setting("active_user") = invalid or get_setting("active_user") = ""
        device_id = devinfo.GetRandomUUID()
    end if
    auth = auth + ", DeviceId=" + Chr(34) + device_id + Chr(34)

    version = appinfo.GetVersion()
    auth = auth + ", Version=" + Chr(34) + version + Chr(34)

    user = get_setting("active_user")
    if user <> invalid and user <> ""
        auth = auth + ", UserId=" + Chr(34) + user + Chr(34)
    end if

    token = get_user_setting("token")
    if token <> invalid and token <> ""
        auth = auth + ", Token=" + Chr(34) + token + Chr(34)
    end if

    request.AddHeader("Authorization", auth)
    return request
end function

function _deleteVoid(req)
    req.setMessagePort(CreateObject("roMessagePort"))
    req.AddHeader("Content-Type", "application/json")
    req.SetRequest("DELETE")
    req.GetToString()

    return true
end function

function _postJson(req, data = "" as string)
    req.setMessagePort(CreateObject("roMessagePort"))
    req.AddHeader("Content-Type", "application/json")
    req.AsyncPostFromString(data)
    resp = wait(30000, req.GetMessagePort())
    if type(resp) <> "roUrlEvent"
        return invalid
    end if

    if resp.getString() = ""
        return invalid
    end if

    json = ParseJson(resp.GetString())

    return json
end function

function _postVoid(req, data = "" as string) as boolean
    req.setMessagePort(CreateObject("roMessagePort"))
    req.AddHeader("Content-Type", "application/json")
    req.AsyncPostFromString(data)
    resp = wait(30000, req.GetMessagePort())
    if type(resp) <> "roUrlEvent"
        return false
    end if

    if resp.GetResponseCode() = 200
        return true
    end if

    if resp.GetResponseCode() = 204
        return true
    end if

    return false
end function

function _getJson(req)
    'req.retainBodyOnError(True)
    'print req.GetToString()
    data = req.GetToString()
    if data = invalid or data = ""
        return invalid
    end if
    json = ParseJson(data)
    return json
end function

function _getString(req)
    data = req.GetToString()
    return data
end function

function _postString(req, data = "" as string)
    req.setMessagePort(CreateObject("roMessagePort"))
    req.AddHeader("Content-Type", "application/json")
    req.AsyncPostFromString(data)
    resp = wait(30000, req.GetMessagePort())
    if type(resp) <> "roUrlEvent"
        return invalid
    end if

    return resp.getString()
end function
