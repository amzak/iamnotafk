import x11/x, x11/xlib

when defined(linux):
  const
    libXss* = "libXss.so(|.1)"

{.pragma: libxss, cdecl, dynlib: libXss, importc.}

type
  TXScreenSaverInfo* {.final.} = object
    window*: TWindow
    state*: cint
    kind*: cint
    til_or_since*: culong
    idle*: culong
    eventMask*: culong
  PXScreenSaverInfo* = ptr TXScreenSaverInfo

proc XScreenSaverQueryInfo*(display: PDisplay, drawable: TWindow, saver_info: PXScreenSaverInfo): cint {.libxss.}
proc XScreenSaverAllocInfo*(): PXScreenSaverInfo {.libxss.}
    