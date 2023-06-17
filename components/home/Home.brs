import "pkg:/source/api/baserequest.brs"
import "pkg:/source/utils/config.brs"
import "pkg:/source/utils/misc.brs"

sub init()
    m.top.overhangTitle = "Home"
    m.top.optionsAvailable = true
    if m.global.session.user.settings["ui.home.splashBackground"] = true
        m.backdrop = m.top.findNode("backdrop")
        m.backdrop.uri = buildURL("/Branding/Splashscreen?format=jpg&foregroundLayer=0.15&fillWidth=1280&width=1280&fillHeight=720&height=720&tag=splash")
    end if
end sub

sub refresh()
    m.top.findNode("homeRows").callFunc("updateHomeRows")
end sub

sub loadLibraries()
    m.top.findNode("homeRows").callFunc("loadLibraries")
end sub
