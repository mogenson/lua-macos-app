# lua-macos-app-template
A template for a self-contained GUI MacOS app bundle using LuaJIT

## Build libraries

### luajit

```
git clone https://github.com/LuaJIT/LuaJIT
cd LuaJIT
MACOSX_DEPLOYMENT_TARGET=$(sw_vers --productVersion) make
cp src/luajit LuaRepl.app/Contents/Resources/luajit
```

### libui-ng

```
git clone https://github.com/libui-ng/libui-ng`
cd libui-ng
nix-shell --packages meson ninja \
  darwin.apple_sdk.frameworks.Foundation \
  darwin.apple_sdk.frameworks.AppKit \
  darwin.apple_sdk.frameworks.Cocoa
meson setup build -Dtests=false -Dexamples=false --buildtype=release
ninja -C build
cp build/meson-out/libui.A.dylib LuaRepl.app/Contents/Resources/libui.dylib
```

## Acknowledgments

- libui.lua from https://github.com/cody271/luajit-libui
- class.lua from https://github.com/lunarmodules/Penlight