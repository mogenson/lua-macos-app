# Lua MacOS App
A sample GUI Lua REPL, showing how to create a self-contained MacOS app using only Lua.

<img width="367" alt="Screenshot 2024-01-07 at 15 08 09" src="https://github.com/mogenson/lua-macos-app/assets/900731/ccde2c1e-e0b4-40f9-a9da-da0f49fc04c1">

## Build LuaJIT

```
git clone https://github.com/LuaJIT/LuaJIT
cd LuaJIT
MACOSX_DEPLOYMENT_TARGET=$(sw_vers --productVersion) make
cp src/luajit LuaRepl.app/Contents/Resources/luajit
```
