sub init()
    ' backgroundUri must be set to an empty string before backgroundColor can be set
    m.top.backgroundUri = ""
    m.top.backgroundColor = "#000000"

    m.PosterOne = m.top.findNode("PosterOne")
    m.PosterOne.uri = "pkg:/images/logo.png"

    m.BounceAnimation = m.top.findNode("BounceAnimation")
    m.BounceAnimation.control = "start" 'Start BounceAnimation

    if get_user_setting("ui.screensaver.splashBackground") = "true"
        m.backdrop = m.top.findNode("backdrop")
        m.backdrop.uri = buildURL("/Branding/Splashscreen?format=jpg&foregroundLayer=0.15&fillWidth=1280&width=1280&fillHeight=720&height=720&tag=splash")
    end if
end sub
