' Functions for making requests to the API
function buildParams(params = {} as object) as string
    ' Take an object of parameters and construct the URL query

    param_array = []
    for each field in params.items()
        item = ""
        if type(field.value) = "String" or type(field.value) = "roString"
            item = field.key + "=" + field.value.trim().EncodeUriComponent()
        else if type(field.value) = "roInteger" or type(field.value) = "roInt"
            item = field.key + "=" + stri(field.value).trim()
            'item = field.key + "=" + str(field.value).trim()
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
            item = field.key + "=" + field.value.EncodeUriComponent()
        end if

        if item <> "" then param_array.push(item)
    end for

    return param_array.join("&")
end function

function buildURL(path as string, params = {} as object) as dynamic
    serverURL = get_url()
    if serverURL = invalid then return invalid

    ' Add intial '/' if path does not start with one
    if path.Left(1) = "/"
        full_url = serverURL + path
    else
        full_url = serverURL + "/" + path
    end if

    if params.count() > 0
        full_url = full_url + "?" + buildParams(params)
    end if

    return full_url
end function

function APIRequest(url as string, params = {} as object) as dynamic
    full_url = buildURL(url, params)
    if full_url = invalid then return invalid

    serverURL = m.global.session.server.url
    if serverURL = invalid then return invalid

    req = createObject("roUrlTransfer")
    req.setUrl(full_url)
    req = authRequest(req)
    ' SSL cert
    if serverURL.left(8) = "https://"
        setCertificateAuthority(req)
    end if

    return req
end function

function getJson(req)
    'req.retainBodyOnError(True)
    data = req.GetToString()
    if data = invalid or data = ""
        return invalid
    end if
    json = ParseJson(data)
    return json
end function

function postVoid(req, data = "" as string) as boolean
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

    return false
end function

function headVoid(req) as boolean
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

function getVoid(req) as boolean
    req.setMessagePort(CreateObject("roMessagePort"))
    req.AddHeader("Content-Type", "application/json")
    req.AsyncGetToString()
    resp = wait(30000, req.GetMessagePort())

    if type(resp) <> "roUrlEvent"
        return false
    end if

    if resp.GetResponseCode() = 200
        return true
    end if

    return false
end function

function postJson(req, data = "" as string)
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

function deleteVoid(req)
    req.setMessagePort(CreateObject("roMessagePort"))
    req.AddHeader("Content-Type", "application/json")
    req.SetRequest("DELETE")
    req.GetToString()

    return true
end function

function get_url()
    serverURL = m.global.session.server.url
    if serverURL <> invalid
        if serverURL.right(1) = "/"
            serverURL = serverURL.left(serverURL.len() - 1)
        end if

        ' append http:// to the start if not specified
        if serverURL.left(7) <> "http://" and serverURL.left(8) <> "https://"
            serverURL = "http://" + serverURL
        end if
    end if
    return serverURL
end function

function getString(req)
    data = req.GetToString()
    return data
end function

function postString(req, data = "" as string)
    req.setMessagePort(CreateObject("roMessagePort"))
    req.AddHeader("Content-Type", "application/json")
    req.AsyncPostFromString(data)
    resp = wait(30000, req.GetMessagePort())
    if type(resp) <> "roUrlEvent"
        return invalid
    end if

    return resp.getString()
end function

' sets the certificate authority by file path on the passed node
sub setCertificateAuthority(request as object) as void
    request.setCertificatesFile("common:/certs/ca-bundle.crt")
end sub

' Takes and returns a roUrlTransfer object after adding a Jellyfin "Authorization" header
function authRequest(request as object) as object
    QUOTE = Chr(34)
    auth = "MediaBrowser" + " Client=" + QUOTE + "Jellyfin Roku" + QUOTE
    auth = auth + ", Device=" + QUOTE + m.global.device.name + " (" + m.global.device.friendlyName + ")" + QUOTE
    auth = auth + ", Version=" + QUOTE + m.global.app.version + QUOTE

    if m.global.session.user.id <> invalid
        auth = auth + ", UserId=" + QUOTE + m.global.session.user.id + QUOTE
        auth = auth + ", DeviceId=" + QUOTE + m.global.device.id + QUOTE
        if m.global.session.user.authToken <> invalid
            auth = auth + ", Token=" + QUOTE + m.global.session.user.authToken + QUOTE
        end if
    else
        auth = auth + ", DeviceId=" + QUOTE + m.global.device.uuid + QUOTE
    end if

    request.AddHeader("Authorization", auth)
    return request
end function
