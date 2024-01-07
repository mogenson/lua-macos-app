#!/bin/sh
--[[ 2>/dev/null
resources="$(dirname "$0")/../Resources"
export LUA_PATH="$resources/?.lua;$resources/?/init.lua"
exec "$resources/luajit" "$0" "$@"
--]]

local objc = require("objc")
local repl = require("repl")
local ffi = require("ffi")
local bit = require("bit")

objc.loadFramework("AppKit")

-- Foundation types
ffi.cdef([[
typedef struct NSEdgeInsets {
    CGFloat top;
    CGFloat left;
    CGFloat bottom;
    CGFloat right;
} NSEdgeInsets;
]])

-- AppKit constants
local NSApplicationActivationPolicyRegular = ffi.new("NSInteger", 0)
local NSBackingStoreBuffered = ffi.new("NSUInteger", 2)

local NSWindowStyleMaskTitled = ffi.new("NSUInteger", bit.lshift(1, 0))
local NSWindowStyleMaskClosable = ffi.new("NSUInteger", bit.lshift(1, 1))
local NSWindowStyleMaskMiniaturizable = ffi.new("NSUInteger", bit.lshift(1, 2))
local NSWindowStyleMaskResizable = ffi.new("NSUInteger", bit.lshift(1, 3))

local NSStackViewGravityTop = ffi.new("NSInteger", 1)
local NSStackViewGravityLeading = ffi.new("NSInteger", 1)
local NSStackViewGravityCenter = ffi.new("NSInteger", 2)
local NSStackViewGravityBottom = ffi.new("NSInteger", 3)
local NSStackViewGravityTrailing = ffi.new("NSInteger", 3)

local NSUserInterfaceLayoutOrientationHorizontal = ffi.new("NSInteger", 0)
local NSUserInterfaceLayoutOrientationVertical = ffi.new("NSInteger", 1)

local NO = ffi.new("BOOL", 0)
local YES = ffi.new("BOOL", 1)

local function NSString(str)
    return objc.NSString:stringWithUTF8String(str)
end

local function runRepl(textField, textView)
    local input = ffi.string(textField.stringValue:UTF8String())
    textField.stringValue = NSString("")

    local output = {}
    table.insert(output, "> ")
    table.insert(output, input)
    table.insert(output, "\n")

    local result, err = repl:eval(input)
    if result then
        table.insert(output, result)
        table.insert(output, "\n")
    end
    if err then
        table.insert(output, err)
        table.insert(output, "\n")
    end

    textView.string = textView.string:stringByAppendingString(NSString(table.concat(output)))
    textView:scrollToEndOfDocument(textView)
end


local function makeAppMenu(app)
    local menubar = objc.NSMenu:alloc():init()
    menubar:autorelease()

    local appMenuItem = objc.NSMenuItem:alloc():init()
    appMenuItem:autorelease()
    menubar:addItem(appMenuItem)
    app:setMainMenu(menubar)

    local appMenu = objc.NSMenu:alloc():init()
    appMenu:autorelease()

    local quitMenuItem = objc.NSMenuItem:alloc():initWithTitle_action_keyEquivalent(NSString("Quit"), "terminate:",
        NSString("q"))
    quitMenuItem:autorelease()
    appMenu:addItem(quitMenuItem)

    local closeMenuItem = objc.NSMenuItem:alloc():initWithTitle_action_keyEquivalent(NSString("Close"), "performClose:",
        NSString("w"))
    closeMenuItem:autorelease()
    appMenu:addItem(closeMenuItem)

    appMenuItem:setSubmenu(appMenu)
end

local function makeAppDelegate(app, textField, textView)
    local butttonClicked = "buttonClicked:"

    local AppDelegateClass = objc.newClass("AppDelegate")
    objc.addMethod(AppDelegateClass, "applicationShouldTerminateAfterLastWindowClosed:", "B@:",
        function(self, cmd)
            print("quitting...")
            return YES
        end)
    objc.addMethod(AppDelegateClass, butttonClicked, "v@:@",
        function(self, cmd, sender)
            runRepl(textField, textView)
        end)

    local appDelegate = objc.AppDelegate:alloc():init()
    appDelegate:autorelease()
    app:setDelegate(appDelegate)

    return objc.NSButton:buttonWithTitle_target_action(NSString("Eval"), appDelegate, butttonClicked)
end


local function main()
    local pool = objc.NSAutoreleasePool:alloc():init()

    local NSApp = objc.NSApplication:sharedApplication()
    assert(NSApp:setActivationPolicy(NSApplicationActivationPolicyRegular) == YES)
    makeAppMenu(NSApp)

    local scrollView = objc.NSTextView:scrollableTextView()
    scrollView:autorelease()

    local textView = scrollView.documentView
    textView.editable = NO

    local textField = objc.NSTextField:alloc():init()
    textField.placeholderString = NSString("Enter Lua Code...")

    local button = makeAppDelegate(NSApp, textField, textView)

    local hStack = objc.NSStackView:alloc():init()
    hStack:autorelease()
    hStack:addView_inGravity(textField, NSStackViewGravityLeading)
    hStack:addView_inGravity(button, NSStackViewGravityTrailing)

    local vStack = objc.NSStackView:alloc():init()
    vStack:autorelease()
    vStack.orientation = NSUserInterfaceLayoutOrientationVertical
    vStack.edgeInsets = ffi.new("NSEdgeInsets", { top = 10, left = 10, bottom = 10, right = 10 })
    vStack:addView_inGravity(scrollView, NSStackViewGravityTop)
    vStack:addView_inGravity(hStack, NSStackViewGravityBottom)

    local rect = ffi.new("CGRect", { origin = { x = 0, y = 0 }, size = { width = 200, height = 300 } })
    local styleMask = bit.bor(NSWindowStyleMaskTitled, NSWindowStyleMaskClosable, NSWindowStyleMaskMiniaturizable,
        NSWindowStyleMaskResizable)

    local window = objc.NSWindow:alloc():initWithContentRect_styleMask_backing_defer(rect, styleMask,
        NSBackingStoreBuffered, NO)
    window:autorelease()
    window.contentView = vStack
    window:setTitle(NSString("LuaREPL"))
    window:makeKeyAndOrderFront(window)

    NSApp:run()
end

main()
