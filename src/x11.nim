import x11/x,
  x11/xlib,
  x11/keysym,
  random,
  asyncdispatch,
  cstrutils,
  pointerInc,
  x11screensaver

const
  stepScale = 0.2f

var
  mouseCurrentX: int
  mouseCurrentY: int

proc crop[T](value: T, lower, upper: T): T =
  if value < lower:
    return lower
  elif value > upper:
    return upper
  return value

proc moveCursorOnce*(display: PDisplay, window: TWindow) {.async.} =
  let width = XDisplayWidth(display, 0)
  let height = XDisplayHeight(display, 0)

  let movementLengthX = width - rand(width*2)
  let movementLengthY = height - rand(height*2)
  let randVector = (float(movementLengthX), float(movementLengthY))

  var nextCoordX, nextCoordY = 0

  for pos in 0..100:
    nextCoordX = mouseCurrentX + int(randVector[0] * float32(pos) * 0.01f * stepScale)
    nextCoordY = mouseCurrentY + int(randVector[1] * float32(pos) * 0.01f * stepScale)

    discard XWarpPointer(
      display, 
      None, 
      window, 
      0, 0, 
      cuint(width), 
      cuint(height), 
      cint(nextCoordX), 
      cint(nextCoordY));
    discard XFlush(display)
    await sleepAsync(5)

  mouseCurrentX = nextCoordX.crop(0, width)
  mouseCurrentY = nextCoordY.crop(0, height)

proc searchWindow*(display: PDisplay, current: TWindow, targetTitle: string): TWindow =
  var title: cstring

  let status = XFetchName(display, current, addr title)
  defer:
    discard XFree(title)
    
  if status > 0 and title.startsWith(targetTitle):
    return current

  var 
    root, parent: TWindow
    children: TWindow
    childrenPtr: PWindow = addr children
    childrenCount: cuint = 0

  let queryResult = XQueryTree(display, current, addr root, addr parent, addr childrenPtr, addr childrenCount)
  defer:
    discard XFree(childrenPtr)

  if queryResult != 0:
    if childrenCount == 0:
      return None

    for i in 0 .. childrenCount-1:
      pointerInc:
        let nextCurrent = childrenPtr + int(i)

        let searchResult = searchWindow(display, nextCurrent[], targetTitle)

        if searchResult != None:
          return searchResult

  return None

proc waitForUserIdle*(display: PDisplay, rootWindow: TWindow, userIdleTimeout: int) {.async.} =
  var info = XScreenSaverAllocInfo()
  defer:
    discard XFree(info)
  info.idle = 0

  while true:
    discard XScreenSaverQueryInfo(display, rootWindow, info)
    if info.idle < culong(userIdleTimeout):
      await sleepAsync(userIdleTimeout div 10)
    else:
      break

proc createKeyEvent(display: PDisplay, window: TWindow, key: TKeySym, modifiers: cuint, eventType: cint): TXEvent =  
  let event = TXKeyEvent(
    display: display,
    window: window,
    root: None,
    subwindow: None,
    time: CurrentTime,
    x: 0,
    y: 0,
    x_root: 0,
    y_root: 0,
    same_screen: 1,
    keycode: cuint(XKeysymToKeycode(display, key)),
    state: modifiers,
    theType: eventType
  )

  return TXEvent(xkey: event)

proc pressKeyAndFlush*(display: PDisplay, window: TWindow, key: TKeySym, modifiers: cuint = 0): TXEvent =
  var keyEvent = createKeyEvent(display, window, key, 0, KeyPress)

  discard XSendEvent(display, keyEvent.xkey.window, 1, KeyPressMask, addr keyEvent)
  discard XFlush(display)

  return keyEvent

proc releaseKey*(event: sink TXEvent) =
  event.xkey.theType = KeyRelease
  discard XSendEvent(event.xkey.display, event.xkey.window, 1, KeyReleaseMask, addr event)

proc pressAltTab*(display: PDisplay, window: TWindow) {.async.} =
  var altEvent = pressKeyAndFlush(display, window, XK_Alt_L)
  await sleepAsync(100)
  var tabEvent = pressKeyAndFlush(display, window, XK_Tab)
  await sleepAsync(100)
  releaseKey(altEvent)
  releaseKey(tabEvent)
  discard XFlush(display)
