sub init()
    m.top.functionName = "keepAwake"

    di = CreateObject("roDeviceInfo")
    m.IPaddress = di.GetIPAddrs().eth1
end sub

' Code adapted from post by greubel
' https://community.roku.com/t5/Roku-Developer-Program/Is-there-a-programmatic-way-to-prevent-Roku-to-go-to-screen/m-p/326080/highlight/true#M17457
sub keepAwake()
    adrs = CreateObject("roSocketAddress")
    adrs.SetAddress(m.IPaddress + ":8060")

    tcp = CreateObject("roStreamSocket")
    tcp.setSendToAddress(adrs)
    tcp.connect()

    obuf = CreateObject("roByteArray")
    eol = Chr(13) + Chr(10)
    obuf.FromAsciiString("POST /keypress/Lit_X HTTP/1.1" + eol + eol)
    z = obuf.Count()
    obuf[z] = 0
    tcp.send(obuf, 0, z)
end sub
