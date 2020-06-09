import x11/x,
  x11/xlib,
  random,
  asyncdispatch,
  cstrutils,
  pointerInc

const
  stepScale = 0.2f

var
  mouseCurrentX: int
  mouseCurrentY: int

proc crop[T](value: var T, lower, upper: T) =
  if value < lower:
    value = lower
  elif value > upper:
    value = upper

proc moveCursorOnce*(display: PDisplay, rootWindow: TWindow) {.async.} =
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
      rootWindow, 
      0, 0, 
      cuint(width), 
      cuint(height), 
      cint(nextCoordX), 
      cint(nextCoordY));
    discard XFlush(display)
    await sleepAsync(5)

  nextCoordX.crop(0, width)
  nextCoordY.crop(0, height)

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