#!/bin/sh
_=[[
resources="$(dirname "$0")/../Resources"
export DYLD_FALLBACK_LIBRARY_PATH="$resources"
export LUA_PATH="$resources/?.lua;$resources/?/init.lua"
exec "$resources/luajit" "$0" "$@"
]]
_ = nil

local ui = require("libui")
local repl = require("repl")

local function main()
    ui.Init()

    local window = ui.Window("Lua REPL", 640, 480, true)
    window.OnClosing = function()
        ui.Quit()
        return true
    end
    ui.OnShouldQuit = function()
        window:Destroy()
        return true
    end

    local vbox = ui.VerticalBox()
    local textbox = ui.MultilineEntry()
    textbox.ReadOnly = true

    vbox.Padded = true
    vbox:Append(ui.Label("Lua Output:"), false)
    vbox:Append(textbox, false)
    vbox:Append(ui.HorizontalSeparator(), false)

    local hbox = ui.HorizontalBox()
    local entry = ui.Entry()
    local button = ui.Button("Eval")
    button.OnClicked = function()
        textbox:Append("> " .. entry.Text .. "\n")
        local result, err = repl:eval(entry.Text)
        if result then
            textbox:Append(result .. "\n")
        end
        if err then
            textbox:Append(err .. "\n")
        end
        entry.Text = ""
    end

    hbox.Padded = true
    hbox:Append(ui.Label("Lua Input:"), false)
    hbox:Append(entry, true)
    hbox:Append(button, false)
    vbox:Append(hbox, true)

    window.Child = vbox
    window.Margined = true
    window:Show()
    ui.Main()
end

main()
