import 
    os,
    asyncdispatch,
    x11/x,
    x11/xlib,
    x11,
    random,
    strutils

from posix import SIGINT, SIGTERM, onSignal

var
  cancellation: Future[void] = newFuture[void]("cancellationFuture")
  target: string = "code"
  userIdleTimeoutNormal = 60000
  userIdleTimeout: int

onSignal(SIGINT, SIGTERM):
  echo "shutting down..."
  cancellation.complete()

proc userIdleTimeoutShort(): int {.inline.} = userIdleTimeoutNormal div 10

proc readParam(key, value: string) =
    case key
        of "-w":
            target = value
        of "-t":
            userIdleTimeoutNormal = parseInt(value) * 1000

proc main() {.async.} =
  if paramCount() < 2:
    echo "usage: iamnotafk -w x11_window_title [-t 60]"
    quit(1)

  for i in 0 .. paramCount() div 2 - 1:
    readParam(paramStr(i*2 + 1), paramStr(i*2 + 2))

  userIdleTimeout = userIdleTimeoutNormal

  echo "target: ", target
  echo "idle timeout: ", userIdleTimeout
  echo "idle timeout short: ", userIdleTimeoutShort()
    
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
    var fut = waitForUserIdle(display, rootWindow, userIdleTimeout) or cancellation
    var userAway = await withTimeout(fut, int(float(userIdleTimeout) * 1.1f))

    if cancellation.finished:
      break

    if userAway:
      echo "user is idle"
      if rand(100) < 10:
        echo "alt tab"
        await pressAltTab(display, targetWindow)
      else:
        await moveCursorOnce(display, targetWindow)
      userIdleTimeout = userIdleTimeoutShort()
    else:
      echo "user is not idle"
      userIdleTimeout = userIdleTimeoutNormal
      continue

waitFor main()
echo "done"