import 
    os,
    asyncdispatch,
    x11/x,
    x11/xlib,
    x11

from posix import SIGINT, SIGTERM, onSignal

const
  userIdleTimeoutNormal = 60000
  userIdleTimeoutShort = 10000

var
  cancellation: Future[void] = newFuture[void]("cancellationFuture")
  userIdleTimeout = 60000

onSignal(SIGINT, SIGTERM):
  echo "shutting down..."
  cancellation.complete()

proc main() {.async.} =
  if paramCount() < 2 or paramStr(1) != "-t":
    echo "usage: iamnotafk -t x11_window_title"
    quit(1)

  let target = paramStr(2)
    
  var display = XOpenDisplay(nil)
  defer:
    discard XCloseDisplay(display)

  let rootWindow = XDefaultRootWindow(display)

  let targetWindow = searchWindow(display, rootWindow, target)
  if targetWindow == None:
    echo "target window not found"
    quit(1)

  discard XRaiseWindow(display, targetWindow)

  while not cancellation.finished:
    echo "waiting for user to be idle..."
    var fut = waitForUserIdle(display, rootWindow, userIdleTimeout, cancellation)
    var userAway = await withTimeout(fut, int(float(userIdleTimeout) * 1.1f))

    if cancellation.finished:
      break

    if userAway:
      echo "user is idle"
      await moveCursorOnce(display, rootWindow)
      userIdleTimeout = userIdleTimeoutShort
    else:
      echo "user is not idle"
      userIdleTimeout = userIdleTimeoutNormal
      continue

waitFor main()
echo "done"