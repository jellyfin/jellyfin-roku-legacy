' Play Audio
sub CreateAudioPlayerView()
    view = CreateObject("roSGNode", "AudioPlayerView")
    view.observeField("state", m.port)
    m.global.sceneManager.callFunc("pushScene", view)
end sub
