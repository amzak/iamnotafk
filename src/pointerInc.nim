template pointerInc*(body: untyped) =
  template `+`[T](p: ptr T, off: int): ptr T =
    cast[ptr type(p[])](cast[ByteAddress](p) +% off * sizeof(p[]))
  
  template `+=`[T](p: ptr T, off: int) =
    p = p + off

  body