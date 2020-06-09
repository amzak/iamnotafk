import x11/x, x11/xlib, random, asyncdispatch

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
