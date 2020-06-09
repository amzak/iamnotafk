import
  x11/x,
  x11/xlib, 
  unittest, 
  ../src/x11screensaver,
  ../src/x11

suite "test x11":
  setup:
    var dsp = XOpenDisplay(nil)
    var rootWnd = XDefaultRootWindow(dsp)
    var info = XScreenSaverAllocInfo()

  teardown:
    discard XCloseDisplay(dsp)
    discard XFree(info)

  test "search for vs code window":
    let result = searchWindow(dsp, rootWnd, "code");
    check(result != None)
  
  test "get screensaver info":
    discard XScreenSaverQueryInfo(dsp, rootWnd, info);
    check(info.idle > 0)

