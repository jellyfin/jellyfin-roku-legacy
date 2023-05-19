import "pkg:/source/utils/config.brs"

sub setDataFromJSON()
    json = m.top.json
    loadFromJSON(json)
end sub

sub loadFromJSON(json)
    m.top.id = json.User.id

    m.top.username = json.User.name
    m.top.token = json.AccessToken
end sub

sub loadFromRegistry(id as string)
    m.top.id = id

    m.top.username = get_user_setting("username")
    m.top.token = get_user_setting("token")
end sub

sub saveToRegistry()
    set_user_setting("username", m.top.username)
    set_user_setting("token", m.top.token)

    users = parseJson(get_setting("available_users", "[]"))
    this_user = invalid
    for each user in users
        if user.id = m.top.id then this_user = user
    end for
    if this_user = invalid
        users.push({
            id: m.top.id,
            username: m.top.username,
            server: m.global.session.server.url
        })
        set_setting("available_users", formatJson(users))
    end if
end sub

sub removeFromRegistry()
    new_users = []
    users = parseJson(get_setting("available_users", "[]"))
    for each user in users
        if m.top.id <> user.id then new_users.push(user)
    end for

    set_setting("available_users", formatJson(new_users))
end sub

function getPreference(key as string)
    return get_user_setting("pref-" + key)
end function

function setPreference(key as string, value as string)
    return set_user_setting("pref-" + key, value)
end function

sub setActive()
    set_setting("active_user", m.top.id)
end sub

sub setServer(hostname as string)
    m.top.server = hostname
end sub
