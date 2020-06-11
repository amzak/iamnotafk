import
  x11/x,
  x11/xlib,
  x11/keysym,
  unittest, 
  ../src/x11screensaver,
  ../src/x11,
  times,
  asyncdispatch

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

  test "asyc cancellation":
    let time = cpuTime()

    var cancellation = newFuture[void]()
    
    proc asyncTest() {.async.} =
      await sleepAsync(5000) or cancellation

    cancellation.complete()
    waitFor(asyncTest())

    let elapsed = cpuTime() - time
    check(elapsed < 5000)