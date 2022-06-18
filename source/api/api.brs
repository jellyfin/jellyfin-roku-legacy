function API()
    instance = {}

    instance["artists"] = artistsActions()
    instance["audio"] = audioActions()
    instance["auth"] = authActions()
    instance["branding"] = brandingActions()
    instance["channels"] = channelsActions()
    instance["clientlog"] = clientlogActions()
    instance["collections"] = collectionsActions()
    instance["devices"] = devicesActions()
    instance["displaypreferences"] = displaypreferencesActions()
    instance["dlna"] = dlnaActions()
    instance["environment"] = environmentActions()
    instance["getutctime"] = getutctimeActions()
    instance["genres"] = genresActions()
    instance["items"] = itemsActions()
    instance["musicgenres"] = musicgenresActions()
    instance["persons"] = personsActions()
    instance["studios"] = studiosActions()
    instance["system"] = systemActions()
    instance["users"] = usersActions()
    instance["web"] = webActions()
    instance["years"] = yearsActions()

    return instance
end function

function artistsActions()
    instance = {}

    ' Gets all artists from a given item, folder, or the entire library.
    instance.get = function(params = {} as object)
        req = _APIRequest("/artists", params)
        return _getJson(req)
    end function

    ' Gets an artist by name.
    instance.getbyname = function(name as string, params = {} as object)
        req = _APIRequest(Substitute("/artists/{0}", name), params)
        return _getJson(req)
    end function

    ' Gets all album artists from a given item, folder, or the entire library.
    instance.getalbumartists = function(params = {} as object)
        req = _APIRequest("/artists/albumartists", params)
        return _getJson(req)
    end function

    ' Get artist image by name.
    instance.getimageurlbyname = function(name as string, imagetype = "primary" as string, imageindex = 0 as integer, params = {} as object)
        return _buildURL(Substitute("/artists/{0}/images/{1}/{2}", name, imagetype, imageindex.ToStr()), params)
    end function

    ' Get artist image by name.
    instance.headimageurlbyname = function(name as string, imagetype = "primary" as string, imageindex = 0 as integer, params = {} as object)
        req = _APIRequest(Substitute("/artists/{0}/images/{1}/{2}", name, imagetype, imageindex.ToStr()), params)
        return _headVoid(req)
    end function

    return instance
end function

function audioActions()
    instance = {}

    ' Gets an audio stream.
    instance.getstreamurl = function(id as string, params = {} as object)
        return _buildURL(Substitute("Audio/{0}/stream", id), params)
    end function

    ' Gets an audio stream.
    instance.headstreamurl = function(id as string, params = {} as object)
        req = _APIRequest(Substitute("Audio/{0}/stream", id), params)
        return _headVoid(req)
    end function

    ' Gets an audio stream.
    instance.getstreamurlwithcontainer = function(id as string, container as string, params = {} as object)
        return _buildURL(Substitute("Audio/{0}/stream.{1}", id, container), params)
    end function

    ' Gets an audio stream.
    instance.headstreamurlwithcontainer = function(id as string, container as string, params = {} as object)
        req = _APIRequest(Substitute("Audio/{0}/stream.{1}", id, container), params)
        return _headVoid(req)
    end function

    ' Gets an audio stream.
    instance.getuniversalurl = function(id as string, params = {} as object)
        return _buildURL(Substitute("Audio/{0}/universal", id), params)
    end function

    ' Gets an audio stream.
    instance.headuniversalurl = function(id as string, params = {} as object)
        throw "System.NotImplementedException: The function is not implemented."
        return false
    end function

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

function brandingActions()
    instance = {}

    ' Get user's splashscreen image
    instance.getsplashscreen = function(params = {} as object)
        return _buildURL("/branding/splashscreen", params)
    end function

    ' Uploads a custom splashscreen.
    instance.postsplashscreen = function(body = {} as object)
        throw "System.NotImplementedException: The function is not implemented."
        return false
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

    ' Gets branding css.
    instance.getcsswithextension = function()
        req = _APIRequest("/branding/css.css")
        return _getJson(req)
    end function

    return instance
end function

function channelsActions()
    instance = {}

    ' Gets available channels.
    instance.get = function(params = {} as object)
        req = _APIRequest("/channels", params)
        return _getJson(req)
    end function

    ' Get channel features.
    instance.getfeatures = function(id as string)
        req = _APIRequest(Substitute("/channels/{0}/features", id))
        return _getJson(req)
    end function

    ' Get channel items.
    instance.getitems = function(id as string, params = {} as object)
        req = _APIRequest(Substitute("/channels/{0}/items", id), params)
        return _getJson(req)
    end function

    ' Get all channel features.
    instance.getallfeatures = function()
        req = _APIRequest("/channels/features")
        return _getJson(req)
    end function

    ' Gets latest channel items.
    instance.getlatestitems = function(params = {} as object)
        req = _APIRequest("/channels/items/latest", params)
        return _getJson(req)
    end function

    return instance
end function

function clientlogActions()
    instance = {}

    ' Upload a document.
    instance.document = function(params = {} as object)
        throw "System.NotImplementedException: The function is not implemented."
        return false
    end function

    return instance
end function

function collectionsActions()
    instance = {}

    ' Creates a new collection.
    instance.create = function(params = {} as object)
        req = _APIRequest("/collections", params)
        return _postJson(req)
    end function

    ' Adds items to a collection.
    instance.additems = function(id as string, params = {} as object)
        req = _APIRequest(Substitute("/collections/{0}/items", id), params)
        return _postVoid(req)
    end function

    ' Removes items from a collection.
    instance.deleteitems = function(id as string, params = {} as object)
        req = _APIRequest(Substitute("/collections/{0}/items", id), params)
        return _deleteVoid(req)
    end function

    return instance
end function

function devicesActions()
    instance = {}

    ' Get Devices.
    instance.get = function(params = {} as object)
        req = _APIRequest("/devices", params)
        return _getJson(req)
    end function

    ' Get info for a device.
    instance.getinfo = function(params = {} as object)
        req = _APIRequest("/devices/info", params)
        return _getJson(req)
    end function

    ' Get options for a device.
    instance.getoptions = function(params = {} as object)
        req = _APIRequest("/devices/options", params)
        return _getJson(req)
    end function

    ' Update device options.
    instance.updateoptions = function(params = {} as object, body = {} as object)
        req = _APIRequest("/devices/options", params)
        return _postVoid(req, FormatJson(body))
    end function

    ' Deletes a device.
    instance.delete = function(params = {} as object)
        req = _APIRequest("/devices", params)
        return _deleteVoid(req)
    end function

    return instance
end function

function displaypreferencesActions()
    instance = {}

    ' Get Display Preferences.
    '  m.api.displaypreferences.get("usersettings", {
    '    "userid": "bde7e54f2d7f45d79525265640239c03",
    '    "client": "roku"
    '})
    instance.get = function(id as string, params = {} as object)
        req = _APIRequest(Substitute("/displaypreferences/{0}", id), params)
        return _getJson(req)
    end function

    ' Update Display Preferences.
    instance.update = function(id, params = {} as object, body = {} as object)
        req = _APIRequest(Substitute("/displaypreferences/{0}", id), params)
        return _postVoid(req, FormatJson(body))
    end function

    return instance
end function

function dlnaActions()
    instance = {}

    ' Get profile infos.
    instance.getprofileinfos = function()
        req = _APIRequest("/dlna/profileinfos")
        return _getJson(req)
    end function

    ' Creates a profile.
    instance.createprofile = function(body = {} as object)
        req = _APIRequest("/dlna/profiles")
        return _postVoid(req, FormatJson(body))
    end function

    ' Updates a profile.
    instance.updateprofile = function(id as string, body = {} as object)
        throw "System.NotImplementedException: The function is not implemented."
        return false
    end function

    ' Gets a single profile.
    instance.getprofilebyid = function(id as string)
        req = _APIRequest(Substitute("/dlna/profiles/{0}", id))
        return _getJson(req)
    end function

    ' Deletes a profile.
    instance.deleteprofile = function(id as string)
        req = _APIRequest(Substitute("/dlna/profiles/{0}", id))
        return _deleteVoid(req)
    end function

    ' Gets the default profile.
    instance.getdefaultprofile = function()
        req = _APIRequest("/dlna/profiles/default")
        return _getJson(req)
    end function

    return instance
end function

function environmentActions()
    instance = {}

    ' Get Default directory browser.
    instance.getdefaultdirectorybrowser = function()
        req = _APIRequest("/environment/defaultdirectorybrowser")
        return _getJson(req)
    end function

    ' Gets the contents of a given directory in the file system.
    instance.getdirectorycontents = function(params = {} as object)
        req = _APIRequest("/environment/directorycontents", params)
        return _getJson(req)
    end function

    ' Gets the parent path of a given path.
    instance.getparentpath = function(params = {} as object)
        req = _APIRequest("/environment/parentpath", params)
        return _getJson(req)
    end function

    ' Gets available drives from the server's file system.
    instance.getdrives = function()
        req = _APIRequest("/environment/drives")
        return _getJson(req)
    end function

    ' Validates path.
    instance.validatepath = function(body = {} as object)
        req = _APIRequest("/environment/validatepath")
        return _postVoid(req, FormatJson(body))
    end function

    return instance
end function

function genresActions()
    instance = {}

    ' Gets all genres from a given item, folder, or the entire library.
    instance.get = function(params = {} as object)
        req = _APIRequest("/genres", params)
        return _getJson(req)
    end function

    ' Gets a genre, by name.
    instance.getbyname = function(name as string, params = {} as object)
        req = _APIRequest(Substitute("/genres/{0}", name), params)
        return _getJson(req)
    end function

    ' Get genre image by name.
    instance.getimageurlbyname = function(name as string, imagetype = "primary" as string, imageindex = 0 as integer, params = {} as object)
        return _buildURL(Substitute("/genres/{0}/images/{1}/{2}", name, imagetype, imageindex.toStr()), params)
    end function

    ' Get genre image by name.
    instance.headimageurlbyname = function(name as string, imagetype = "primary" as string, imageindex = 0 as integer, params = {} as object)
        req = _APIRequest(Substitute("/genres/{0}/images/{1}/{2}", name, imagetype, imageindex.toStr()), params)
        return _headVoid(req)
    end function

    return instance
end function

function getutctimeActions()
    instance = {}

    ' Get profile infos.
    instance.get = function()
        req = _APIRequest("/getutctime")
        return _getJson(req)
    end function

    return instance
end function

function itemsActions()
    instance = {}

    ' Gets legacy query filters.
    instance.getfilters = function(params = {} as object)
        req = _APIRequest("/items/filters", params)
        return _getJson(req)
    end function

    ' Gets query filters.
    instance.getfilters2 = function(params = {} as object)
        req = _APIRequest("/items/filters2", params)
        return _getJson(req)
    end function

    ' Get item image infos.
    instance.getimages = function(id as string)
        req = _APIRequest(Substitute("/items/{0}/images", id))
        return _getJson(req)
    end function

    ' Delete an item's image.
    instance.deleteimage = function(id as string, imagetype as string)
        throw "System.NotImplementedException: The function is not implemented."
        return false
    end function

    ' Set item image.
    instance.postimage = function(id as string, imagetype as string, body = {} as object)
        throw "System.NotImplementedException: The function is not implemented."
        return false
    end function

    ' Gets the item's image.
    instance.getimageurl = function(id as string, imagetype = "primary" as string, imageindex = 0 as integer, params = {} as object)
        return _buildURL(Substitute("/items/{0}/images/{1}/{2}", id, imagetype, imageindex.toStr()), params)
    end function

    ' Gets the item's image.
    instance.headimageurlbyname = function(id as string, imagetype = "primary" as string, imageindex = 0 as integer, params = {} as object)
        req = _APIRequest(Substitute("/items/{0}/images/{1}/{2}", id, imagetype, imageindex.toStr()), params)
        return _headVoid(req)
    end function

    ' Delete an item's image.
    instance.deleteimagebyindex = function(id as string, imagetype = "primary" as string, imageindex = 0 as integer)
        throw "System.NotImplementedException: The function is not implemented."
        return false
    end function

    ' Updates the index for an item image.
    instance.updateimageindex = function(id as string, imagetype = "primary" as string, imageindex = 0 as integer, params = {} as object)
        req = _APIRequest(Substitute("/items/{0}/images/{1}/{2}/index", id, imagetype, imageindex.toStr()), params)
        return _postVoid(req)
    end function

    return instance
end function

function musicgenresActions()
    instance = {}

    ' Get music genre image by name.
    instance.getimageurlbyname = function(name as string, imagetype = "primary" as string, imageindex = 0 as integer, params = {} as object)
        return _buildURL(Substitute("/musicgenres/{0}/images/{1}/{2}", name, imagetype, imageindex.toStr()), params)
    end function

    ' Get music genre image by name.
    instance.headimageurlbyname = function(name as string, imagetype = "primary" as string, imageindex = 0 as integer, params = {} as object)
        req = _APIRequest(Substitute("/musicgenres/{0}/images/{1}/{2}", name, imagetype, imageindex.toStr()), params)
        return _headVoid(req)
    end function

    return instance
end function

function personsActions()
    instance = {}

    ' Get person image by name.
    instance.getimageurlbyname = function(name as string, imagetype = "primary" as string, imageindex = 0 as integer, params = {} as object)
        return _buildURL(Substitute("/persons/{0}/images/{1}/{2}", name, imagetype, imageindex.toStr()), params)
    end function

    ' Get person image by name.
    instance.headimageurlbyname = function(name as string, imagetype = "primary" as string, imageindex = 0 as integer, params = {} as object)
        req = _APIRequest(Substitute("/persons/{0}/images/{1}/{2}", name, imagetype, imageindex.toStr()), params)
        return _headVoid(req)
    end function

    return instance
end function

function studiosActions()
    instance = {}

    ' Get studio image by name.
    instance.getimageurlbyname = function(name as string, imagetype = "thumb" as string, imageindex = 0 as integer, params = {} as object)
        return _buildURL(Substitute("/studios/{0}/images/{1}/{2}", name, imagetype, imageindex.toStr()), params)
    end function

    ' Get studio image by name.
    instance.headimageurlbyname = function(name as string, imagetype = "thumb" as string, imageindex = 0 as integer, params = {} as object)
        req = _APIRequest(Substitute("/studios/{0}/images/{1}/{2}", name, imagetype, imageindex.toStr()), params)
        return _headVoid(req)
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

    ' Gets application configuration.
    instance.getconfiguration = function()
        req = _APIRequest("/system/configuration")
        return _getJson(req)
    end function

    ' Updates application configuration.
    instance.updateconfiguration = function(body = {} as object)
        req = _APIRequest("/system/configuration")
        return _postVoid(req, FormatJson(body))
    end function

    ' Gets a named configuration.
    instance.getconfigurationbyname = function(name as string)
        req = _APIRequest(Substitute("/system/configuration/{0}", name))
        return _getJson(req)
    end function

    ' Updates named configuration.
    instance.updateconfigurationbyname = function(name as string)
        throw "System.NotImplementedException: The function is not implemented."
        return false
    end function

    ' Gets a default MetadataOptions object.
    instance.getdefaultmetadataoptions = function()
        req = _APIRequest("/system/configuration/metadataoptions/default")
        return _getJson(req)
    end function

    ' Updates the path to the media encoder.
    instance.updatemediaencoderpath = function(body = {} as object)
        throw "System.NotImplementedException: The function is not implemented."
        return false
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
    instance.create = function(body = {} as object)
        req = _APIRequest("/users/new")
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

    ' Sets the user image.
    instance.updateimage = function(id as string, imagetype as string, imageindex = 0 as integer, body = {} as object)
        throw "System.NotImplementedException: The function is not implemented."
        return false
    end function

    ' Delete the user's image.
    instance.deleteimage = function(id as string, imagetype as string, imageindex = 0 as integer)
        throw "System.NotImplementedException: The function is not implemented."
        return false
    end function

    ' Get user profile image.
    instance.getimageurl = function(id as string, imagetype = "primary" as string, imageindex = 0 as integer, params = {} as object)
        return _buildURL(Substitute("/users/{0}/images/{1}/{2}", id, imagetype, imageindex.toStr()), params)
    end function

    ' Get music genre image by name.
    instance.headimageurl = function(id as string, imagetype = "primary" as string, imageindex = 0 as integer, params = {} as object)
        req = _APIRequest(Substitute("/users/{0}/images/{1}/{2}", id, imagetype, imageindex.toStr()), params)
        return _headVoid(req)
    end function

    return instance
end function

function webActions()
    instance = {}

    ' Gets a dashboard configuration page.
    instance.getconfigurationpage = function()
        throw "System.NotImplementedException: The function is not implemented."
        return false
    end function

    ' Gets a dashboard configuration page.
    instance.getconfigurationpages = function()
        req = _APIRequest("/web/configurationpages")
        return _getJson(req)
    end function

    return instance
end function

function yearsActions()
    instance = {}

    ' Gets years
    instance.get = function(params = {} as object)
        req = _APIRequest("/years", params)
        return _getJson(req)
    end function

    ' Gets a year.
    instance.getyear = function(year as string, params = {} as object)
        req = _APIRequest(Substitute("/years/{0}", year), params)
        return _getJson(req)
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

    path = path.Replace(" ", "%20")

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
    
    ' Remove trailing slash
    if base.right(1) = "/"
        base = base.left(base.len() - 1)
    end if

    ' Ensure protocol is at beginning of URL
    if base.left(7) <> "http://" and base.left(8) <> "https://"
        base = "http://" + base
    end if

    return base
end function

function _authorize_request(request)
    devinfo = CreateObject("roDeviceInfo")
    appinfo = CreateObject("roAppInfo")

    auth = "MediaBrowser Client=" + Chr(34) + "Jellyfin Roku" + Chr(34)

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

    auth = auth + ", Version=" + Chr(34) + appinfo.GetVersion() + Chr(34)

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

function _headVoid(req) as boolean
    req.setMessagePort(CreateObject("roMessagePort"))
    req.AddHeader("Content-Type", "application/json")
    req.AsyncHead()
    resp = wait(30000, req.GetMessagePort())
    if type(resp) <> "roUrlEvent"
        return false
    end if

    if resp.GetResponseCode() = 200
        return true
    end if

    return false
end function

function _getJson(req)
    data = req.GetToString()
    if data = invalid or data = ""
        return invalid
    end if
    json = ParseJson(data)
    return json
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
