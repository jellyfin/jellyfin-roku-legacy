' needed for set_user_setting() and unset_user_setting()
import "pkg:/source/utils/session.bs"

' Read config tree from json config file and return
function GetConfigTree()
    return ParseJSON(ReadAsciiFile("pkg:/settings/settings.json"))
end function

' Generic registry accessors
function registry_read(key, section = invalid)
    if section = invalid then return invalid
    reg = CreateObject("roRegistrySection", section)
    if reg.exists(key) then return reg.read(key)
    return invalid
end function

sub registry_write(key, value, section = invalid)
    if section = invalid then return
    reg = CreateObject("roRegistrySection", section)
    reg.write(key, value)
    reg.flush()
end sub

sub registry_delete(key, section = invalid)
    if section = invalid then return
    reg = CreateObject("roRegistrySection", section)
    reg.delete(key)
    reg.flush()
end sub

' Return all data found inside a registry section
function RegistryReadAll(section as string) as dynamic
    if section = "" then return invalid

    registry = CreateObject("roRegistrySection", section)
    regKeyList = registry.GetKeyList()
    registryData = {}
    for each item in regKeyList
        ' ignore session related tokens
        if item <> "token" and item <> "username" and item <> "password"
            if registry.Exists(item)
                registryData.AddReplace(item, registry.Read(item))
            end if
        end if
    end for

    return registryData
end function

' "Jellyfin" registry accessors for the default global settings
function get_setting(key, default = invalid)
    value = registry_read(key, "Jellyfin")
    if value = invalid then return default
    return value
end function

sub set_setting(key, value)
    registry_write(key, value, "Jellyfin")
end sub

sub unset_setting(key)
    registry_delete(key, "Jellyfin")
end sub

' User registry accessors for the currently active user
function get_user_setting(key as string) as dynamic
    if key = "" or m.global.session.user.id = invalid then return invalid
    value = registry_read(key, m.global.session.user.id)
    return value
end function

sub set_user_setting(key as string, value as dynamic)
    if m.global.session.user.id = invalid then return
    session.user.settings.Save(key, value)
    registry_write(key, value, m.global.session.user.id)
end sub

sub unset_user_setting(key as string)
    if m.global.session.user.id = invalid then return
    session.user.settings.Delete(key)
    registry_delete(key, m.global.session.user.id)
end sub

' Recursivly search the config tree for entry with settingname equal to key
function findConfigTreeKey(key as string, tree)
    for each item in tree
        if item.settingName <> invalid and item.settingName = key then return item

        if item.children <> invalid and item.children.Count() > 0
            result = findConfigTreeKey(key, item.children)
            if result <> invalid then return result
        end if
    end for

    return invalid
end function
