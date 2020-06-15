# Package

version       = "0.1.0"
author        = "Andrey Zak"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["iamnotafk"]

# Dependencies

requires "nim >= 1.2.0", "x11"

task release, "build in release":
  exec "nimble build -y -d:release --opt:speed"