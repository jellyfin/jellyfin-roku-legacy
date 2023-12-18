import "pkg:/source/roku_modules/log/LogMixin.brs"

sub init()
    ' initialize the log manager. second param sets log output:
    ' 1 error, 2 warn, 3 info, 4 verbose, 5 debug
    _rLog = log_initializeLogManager(["log_PrintTransport"], 5) 'bs:disable-line
end sub
' Function called when the screen is displayed by the screen manager
' It is expected that screens override this function to handle focus
' managmenet and any other actions required on screen shown
sub OnScreenShown()
    if m.top.lastFocus <> invalid
        m.top.lastFocus.setFocus(true)
    else
        m.top.setFocus(true)
    end if
end sub

' Function called when the screen is hidden by the screen manager
' It is expected that screens override this function if required,
' to handle focus any actions required on the screen being hidden
sub OnScreenHidden()
end sub

