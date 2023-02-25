sub init()
    m.posterImg = m.top.findNode("posterImg")
    m.name = m.top.findNode("pLabel")
    m.role = m.top.findNode("subTitle")

    m.deviceInfo = CreateObject("roDeviceInfo")
end sub

sub showContent()
    if m.top.itemContent <> invalid
        cont = m.top.itemContent
        m.name.text = cont.labelText
        m.name.maxWidth = cont.imageWidth
        m.role.maxWidth = cont.imageWidth
        m.posterImg.uri = cont.posterUrl
        m.posterImg.width = cont.imageWidth
        m.role.Text = cont.subTitle
    else
        m.role.text = tr("Unknown")
        m.posterImg.uri = "pkg:/images/baseline_person_white_48dp.png"
    end if
end sub

sub focusChanged()
    if m.top.itemHasFocus = true
        m.name.repeatCount = -1
        m.role.repeatCount = -1
    else
        m.name.repeatCount = 0
        m.role.repeatCount = 0
    end if

    if m.deviceInfo.IsAudioGuideEnabled() = true
        txt2Speech = CreateObject("roTextToSpeech")
        txt2Speech.Flush()
        txt2Speech.Say(m.name.text)
        txt2Speech.Say(m.role.text)
    end if
end sub
