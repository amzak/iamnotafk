import
    x11/xlib, 
    unittest, 
    ../src/x11screensaver

suite "test x11 screensaver stuff":
    setup:
        var dsp = XOpenDisplay(nil)
        let rootWnd = XDefaultRootWindow(dsp)    
        var info = XScreenSaverAllocInfo()

    teardown:
        discard XCloseDisplay(dsp)
        discard XFree(info)

    test "get screensaver info":
        discard XScreenSaverQueryInfo(dsp, rootWnd, info);
        check(info.idle > 0)