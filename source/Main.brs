sub Main (args as dynamic) as void
    ' The main function that runs when the application is launched.
    m.screen = CreateObject("roSGScreen")
    ' Set global constants
    setConstants()
    ' Write screen tracker for screensaver
    WriteAsciiFile("tmp:/scene.temp", "")
    MoveFile("tmp:/scene.temp", "tmp:/scene")

    m.port = CreateObject("roMessagePort")
    m.screen.setMessagePort(m.port)
    ' Set any initial Global Variables
    m.global = m.screen.getGlobalNode()
    SaveAppToGlobal()
    SaveDeviceToGlobal()
    session.Init()

    m.scene = m.screen.CreateScene("JFScene")
    m.scene.observeField("exit", m.port)
    m.screen.show() ' vscode_rale_tracker_entry

    jellyfin = new App(m.screen, m.port, m.scene, args)
    jellyfin.run()
end sub
