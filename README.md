# Creating a MacOS app with Lua
And nothing else! No compiled code. No XCode.

https://medium.com/@michael.mogenson/write-a-macos-app-with-lua-342148381e25

Here is a small project that helped me explore the following topics:

I was curious to learn more about a few niche topics:
- How MacOS apps are packaged
- How to bundle a self-contained scripting language
- How to compile and run Lua code on the fly
- How to create a GUI app with Lua
- How LuaJIT's FFI interface works

Here's the app that we're going to make:

<img width="367" alt="Screenshot 2024-01-07 at 15 08 09" src="https://github.com/mogenson/lua-macos-app/assets/900731/ccde2c1e-e0b4-40f9-a9da-da0f49fc04c1">

Below is a small project that helped me explore these questions. I'm going to walk through the process of making a Lua REPL (named for the interactive read-evaluate-print-loop of interpreted languages like Lua and Python. Our app will (creatively) be named LuaREPL. It is a MacOS app with a single text entry line, an Eval button, and a multi-line text output area. User entered code is fed from the text entry, evaluated by the Lua interpreter, and printed to the text output. This app is so simple, it's better used as a template for creating a more substantial app.
Some knowledge of Lua, C, Objective-C, and MacOS/iOS app development is useful but not required. If there are components that do not make sense when initially presented, hopefully they will when we put everything together at the end.

##Why?

I don't know. I'm so bad at answering the question why. Ask me how. The next 500 lines of text are about how.
I saw a video about writing an Android app in C. The author explored the Android OS and determined the minimal setup required to draw to the screen. I wanted to do something similar with Lua, my favorite small language. I own a MacBook. Could I create a native MacOS app without first downloading an 12GB XCode installation image? Could I do everything from scratch, instead of using (fabulous) projects like LÖVE (a C++ game engine with Lua bindings) or Libui (a cross platform UI library for C)?
I suppose this would be good for an internal tool at a company. Distribute a single Lua text file that employees would run as an app. Update that text file and the app updates. No need to go through Apple's App Store for distribution.

###Continuing on…

This article will go through the above topics of learning in reverse order. Starting with…

> Note: for clarity, some error handling and extended features are removed from the code snippets presented in this article.

## LuaJIT

First, we need Lua to build our app, but we're going to use a special version of Lua called LuaJIT. What is LuaJIT? [LuaJIT](https://luajit.org/index.html) is a Just-In-Time compiler and drop in replacement for the standard Lua interpreter. There are numerous ways to install LuaJIT on MacOS. However, since we will eventually want to package LuaJIT into our final, self-contained, MacOS app, let's build it from source.

You said we wouldn't need to compile anything? Ya I lied. You can brew install luajit if you want. But for bundling luajit with our app, it's not hard to build. I promise.

No dependencies besides make and a C compiler are required. Clone the LuaJIT repo and build with:

```bash
$ git clone https://github.com/LuaJIT/LuaJIT
$ cd LuaJIT
$ MACOSX_DEPLOYMENT_TARGET=$(sw_vers --productVersion) make
```

The MACOSX_DEPLOYMENT_TARGET environmental variable must be set during building. I'm only targeting my own computer. At the time of writing, the output of sw_vers --productVersion is "14.1.1".

The resulting `luajit` binary executable will be in the src directory. This stand-alone executable will eventually be copied into our MacOS app. The Lua interpreter, Lua standard library, and LuaJIT specific libraries are all included in the single `luajit` file. Compared to the hundreds of files in specific locations that are needed for the Python interpreter and standard library, this portable Lua interpreter is easy to include inside our app.

## LuaJIT's FFI interface

Besides being very fast at running Lua code, LuaJIT has a fantastic foreign function intervace [(or FFI)](https://luajit.org/ext_ffi_api.html), that lets it call into code written in other languages, using the C function calling convention. LuaJIT will parse declarations from a C header, generate bindings, and do some type conversion automatically. This makes it really easy to call C code from LuaJIT. We will use the FFI module to call into native MacOS libraries to construct and show our app. Here's a simple FFI example:

```lua
local ffi = require("ffi")

ffi.cdef([[
  int printf(const char *fmt, ...);
]])

ffi.C.printf("Hello %s!", "world")
```

The multi-line string passed to `ffi.cdef` contains the prototype for libc's `printf` function. LuaJIT's FFI parser can recognize that this is a variadic C function. A Lua binding is created and added to the `ffi.C` namespace. When this `ffi.C.printf` function is called, LuaJIT knows that the string arguments need to be converted into `\0` terminated char pointers, and does so!

This is fun, but we want to do something MacOS specific to reach our end goal of creating a MacOS app. But, most of the MacOS core libraries are written in [Objective-C](https://en.wikipedia.org/wiki/Objective-C), not C. Objective-C is a message passing language, where named objects are operated on by sending formatted messages to object methods. Here's an Objective-C example to write to the MacOS clipboard.

```objective-c
#import <Cocoa/Cocoa.h>

int main() {
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [pboard clearContents];
    [pboard setString:@"Hello from Objective-C!"
            forType:NSPasteboardTypeString];
    return 0;
}
```

However, Objective-C is a strict superset of C. All of the message passing is done with a few C functions and a lot of type casting. Here is the same example in C.

```c
#include <objc/NSObjCRuntime.h>
#include <objc/objc-runtime.h>

extern id const NSPasteboardTypeString;

int main() {
    const char *str = "Hello from C!";

    Class NSPasteboard = objc_getClass("NSPasteboard");
    id pboard = ((id (*)(Class, SEL))objc_msgSend)(NSPasteboard, sel_registerName("generalPasteboard"));

    ((void (*)(id, SEL))objc_msgSend)(pboard, sel_registerName("clearContents"));

    Class NSString = objc_getClass("NSString");
    id nsStr = ((id (*)(Class, SEL, const char *))objc_msgSend)(NSString, sel_registerName("stringWithUTF8String:"), str);

    ((bool (*)(id, SEL, id, id))objc_msgSend)(pboard, sel_registerName("setString:forType:"), nsStr, NSPasteboardTypeString);

    return 0;
}
```

> Thanks to Nathan Craddock for showing the [relationship between Objective-C and C](https://nathancraddock.com/blog/2023/writing-to-the-clipboard-the-hard-way)

Let's go over the C functions used above. We use `objc_getClass` to get an object by name, `sel_registerName` to get a selector (which is a handle) to an object method by name, and `objc_msgSend` to send a message to an object's selector.

We could compile this C program with some glue code to use as a Lua module. But with LuaJIT's FFI interface, we can call these C functions directly from Lua. The result of translating the C example above into Lua looks like this:

```lua
local ffi = require("ffi")
local C = ffi.C

ffi.cdef([[
  typedef struct objc_object *id;
  typedef struct objc_selector *SEL;
  id objc_getClass(const char*);
  SEL sel_registerName(const char*);
  id objc_msgSend(id,SEL);
  id NSPasteboardTypeString;
]])

ffi.load("/System/Library/Frameworks/AppKit.framework/AppKit")

function main()
    local str = ffi.cast("char*", "Hello from Lua!")

    local pboard = C.objc_msgSend(C.objc_getClass("NSPasteboard"),
        C.sel_registerName("generalPasteboard"))

    C.objc_msgSend(pboard, C.sel_registerName("clearContents"))

    local nsStr = ffi.cast("id(*)(id,SEL,char*)", C.objc_msgSend)(
        C.objc_getClass("NSString"),
        C.sel_registerName("stringWithUTF8String:"),
        str)

    local ret = ffi.cast("bool(*)(id,SEL,id,id)", C.objc_msgSend)(pboard,
        C.sel_registerName("setString:forType:"),
        nsStr,
        C.NSPasteboardTypeString)

    return ret
end

local ret = main()
os.exit(ret)
```

Instead of including headers and linking libraries at compile time. We load the `AppKit` shared library (or framework in Apple language) at runtime. Loading `AppKit` is enough to also load the Objective-C runtime. We define our C functions, a few C types for `id` and `SEL`, and the external constant `NSPasteboardTypeString`. For each step, we use `ffi.cast` to cast the `objc_msgSend` function into the required form. Since LuaJIT can no longer determine the correct argument type from the top level C definitions, we help it out by casting the "Hello from Lua!" string into a char pointer.

## Objective-C Introspection

The process for calling any method in Objective-C is the same: get the receiver class or object, get the selector, collect the arguments, cast `objc_msgSend` to the right signature, and call. However, manually casting each types back and forth is tedious and very verbose. 

Objective-C provides some functions for checking if a method exists for a class or object and looking up the call signature of a method. This is called introspection. We can wrap these method introspection functions in some Lua helper functions that will automatically cast `objc_msgSend` and the provided arguments to the right signature based on the method name.

Our app contains a module named [`objc.lua`](https://github.com/mogenson/lua-macos-app/blob/main/LuaRepl.app/Contents/Resources/objc.lua) to handle the Lua to Objective-C dispatching. We'll have to add some functionality to this module before we can build our app's interface.  Let's look at how the module's `msgSend` function looks up method information to call Objective-C methods:

```lua
local function msgSend(receiver, selector, ...)
    local method = getMethod(receiver, selector)

    local char_ptr = C.method_copyReturnType(method)
    local objc_type = ffi.string(char_ptr)
    C.free(char_ptr)
    local c_type = type_encoding[objc_type]
    local signature = {}
    table.insert(signature, c_type)
    table.insert(signature, "(*)(")

    local num_method_args = C.method_getNumberOfArguments(method)
    for i = 1, num_method_args do
        char_ptr = C.method_copyArgumentType(method, i - 1)
        objc_type = ffi.string(char_ptr)
        C.free(char_ptr)
        c_type = type_encoding[objc_type]
        table.insert(signature, c_type)
        if i < num_method_args then table.insert(signature, ",") end
    end
    table.insert(signature, ")")
    local signature = table.concat(signature)

    return ffi.cast(signature, C.objc_msgSend)(receiver, selector, ...)
end
```

First, we get a pointer to a method of type struct `objc_method`. Using `getMethod`. This is a Lua wrapper that calls either `objc_getClassMethod` if the receiver is a class or `objc_getInstanceMethod` if the receiver is an object. We use this method pointer to query properties about the method, starting with it's return type.

The `method_copyReturnType` function returns a C string (that we have to free later) with the method return type. But this string doesn't include the C type, it uses the [Objective-C type encoding notation](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100). For example "c" represents  a char, "i" represents an int and, "@" means an Objective-C object. We use a table to map the Objective-C encoded type to the C type:

```lua
local type_encoding = {
    ["c"] = "char",
    ["i"] = "int",
    ["s"] = "short",
    ["l"] = "long",
    ["q"] = "NSInteger",
    ["C"] = "unsigned char",
    ["I"] = "unsigned int",
    ["S"] = "unsigned short",
    ["L"] = "unsigned long",
    ["Q"] = "NSUInteger",
    ["f"] = "float",
    ["d"] = "double",
    ["B"] = "BOOL",
    ["v"] = "void",
    ["*"] = "char*",
    ["@"] = "id",
    ["#"] = "Class",
    [":"] = "SEL",
}
```

The rest of `msgSend` is querying the number of method arguments with `methodGetNumberOfArguments`, looking up each argument's type with `method_copyArgumentType`, converting the encoded type to a C type, and appending to a C function signature table. After we concatenate the table of C types, we have the function signature string that we can use to cast the `objc_msgSend` function. For example, calling `msgSend` with `NSApplication` for the receiver and [`setActivationPolicy:`](https://developer.apple.com/documentation/appkit/nsapplication/1428621-setactivationpolicy?language=objc) for the selector generates an anonymous C function signature of `BOOL(*)(Class,SEL,NSInteger)`.

## Metatables

The Lua language uses a feature called [metatables](https://www.lua.org/pil/13.html) to set the behavior of tables and other types (similar to [dunder methods](https://mathspp.com/blog/pydonts/dunder-methods) in Python). We can use metatables to fit our helper functions into some convenient Lua syntax and continue to make our code less verbose. Our `objc.lua` module has an `objc` table to hold the Lua functions we've created so far. We use setmetatable to create a custom `__index` function that calls `objc_lookUpClass`. This function is called with an argument for the table and key every time the `objc` table is indexed but an entry is not found. We'll treat the key argument for this function as an Objective-C class name to look up. Now we can do `objc.NSApplication` to get a pointer of type `struct objc_class` for the `NSApplication` class.

```lua
local objc = setmetatable({
    msgSend = msgSend,
}, {
    __index = function(_, name)
        return C.objc_lookUpClass(name)
    end
})
```

We can also set a metatable with a custom `__index` function for the `struct objc_class` type. This time, we'll treat the key argument as the selector for a method to call on the class. Instead of a value, we create and return a function with `self` as the first argument. This matches Lua's normal syntax for calling a Lua method by using the `()` operator to call the function returned by `__index` and Lua's `:` syntax to pass `self` as the first argument. 

Since Objective-C uses `:` as part of selector names, but that's a reserved token for Lua, we'll write our selector names in Lua with `_` and substitute the characters before calling `sel_registerName`. If the selector name doesn't end with `_`, we'll add one so all selector names have a final `:`.

```lua
ffi.metatype("struct objc_class", {
    __index = function(class, selector)
        return function(self, ...)
            assert(class == self)
            if selector:sub(-1) ~= "_" then
                selector = selector .. "_"
            end
            selector = selector:gsub("_", ":")
            return msgSend(self, C.sel_registerName(selector), ...)
        end
    end
})
```

With this we can do `objc.NSApplication:setActivationPolicy(1)` to lookup the `NSApplication` class and call it's `setActivationPolicy:` method. Way more concise than:

```lua
local class = C.objc_getClass("NSApplication")
local selector = C.sel_registerName("setActivationPolicy:")
ffi.cast("BOOL(*)(Class,SEL,NSInteger)", C.objc_msgSend)(class, selector, 1)
```

## Delegates

There's one last important part to the way that Objective-C frameworks like AppKit work: delegates. If you want to receive events and notifications from a class, you need to create another class with some predefined methods and set it as the delegate for the first class.

Here's how to make a button and use a delegate to get a callback every time the button is clicked. We'll use this for the Eval button of our app.

```lua
local ButtonDelegateClass = objc.newClass("ButtonDelegate")

objc.addMethod(ButtonDelegateClass, "buttonClicked:", "v@:@",
    function(self, cmd, sender)
        print("button clicked!")
    end)

local buttonDelegate = objc.ButtonDelegate:alloc():init()

local button = objc.NSButton:buttonWithTitle_target_action("Button Title",
                   buttonDelegate, "buttonClicked:")
```

We use `newClass` to create a new delegate class and `addMethod` to register a Lua function as a callback for the `buttonClicked:` selector. Then we allocate an instance of our delegate class and create a new `NSButton` with our delegate instance as the target and the `buttonClicked:` selector as the action.

Now we just need to implement `newClass` and `addMethod`. First, `newClass` creates a new class with the provided name, that inherits from the base `NSObject` class, and registers it with the Objective-C runtime.

```lua
local function newClass(name)
    local super_class = C.objc_lookUpClass("NSObject")
    local class = C.objc_allocateClassPair(super_class, name, 0)
    C.objc_registerClassPair(class)
    return class
end
```

Next, `addMethod` accepts the class, a selector name, a string that defines the method signature in Objective-C type encoding format, and the Lua callback function. Similar to `msgSend`, we generate the C function signature from the Objective-C type encoding. We then cast the Lua callback function into a C function pointer, then into a generic `typedef id (*IMP)(id, SEL, ...)` implementation function pointer type that Objective-C expects. The class, selector, implementation, and encoded types are used to register the method for the class with `class_addMethod`.

```lua
local function addMethod(class, selector, types, func)
    local selector = C.sel_registerName(selector)

    local signature = {}
    table.insert(signature, type_encoding[types:sub(1, 1)])
    table.insert(signature, "(*)(")
    for i = 2, #types do
        table.insert(signature, type_encoding[types:sub(i, i)])
        if i < #types then table.insert(signature, ",") end
    end
    table.insert(signature, ")")
    local signature = table.concat(signature)

    local imp = ffi.cast("IMP", ffi.cast(signature, func))
    C.class_addMethod(class, selector, imp, types)
end
```

## App Layout

We now have all the Objective-C pieces we need to create our app. The main function of our LuaREPL app can be seen below:

```lua
local function main()
    local NSApp = objc.NSApplication:sharedApplication()
    NSApp:setActivationPolicy(NSApplicationActivationPolicyRegular)
    makeAppMenu(NSApp)

    local scrollView = objc.NSTextView:scrollableTextView()

    local textView = scrollView.documentView

    local textField = objc.NSTextField:alloc():init()
    textField.placeholderString = NSString("Enter Lua Code...")

    local button = makeAppDelegate(NSApp, textField, textView)

    local hStack = objc.NSStackView:alloc():init()
    hStack:addView_inGravity(textField, NSStackViewGravityLeading)
    hStack:addView_inGravity(button, NSStackViewGravityTrailing)

    local vStack = objc.NSStackView:alloc():init()
    vStack.orientation = NSUserInterfaceLayoutOrientationVertical
    vStack.edgeInsets = ffi.new("NSEdgeInsets", { top = 10, left = 10, bottom = 10, right = 10 })
    vStack:addView_inGravity(scrollView, NSStackViewGravityTop)
    vStack:addView_inGravity(hStack, NSStackViewGravityBottom)

    local rect = ffi.new("CGRect", { origin = { x = 0, y = 0 }, size = { width = 200, height = 300 } })
    local styleMask = bit.bor(NSWindowStyleMaskTitled, NSWindowStyleMaskClosable, NSWindowStyleMaskMiniaturizable,
        NSWindowStyleMaskResizable)

    local window = objc.NSWindow:alloc():initWithContentRect_styleMask_backing_defer(rect, styleMask,
        NSBackingStoreBuffered, NO)
    window.contentView = vStack
    window:setTitle(NSString("LuaREPL"))
    window:makeKeyAndOrderFront(window)

    NSApp:run()
end
```

The layout is pretty simple. There is vertical stack that contains a text view within a scroll view (for showing Lua REPL output) and a horizontal stack. The horizontal stack contains an editable text field and an  button for code evaluation. The end result looks like the image at the beginning of this article.

A delegate is set up to call the following runRepl function on a click of the eval button. This function takes the text field and text view. It collects the input string in the text field and echos it to the text view after a ">" character, so the user can see their input history. It also calls the `repl:eval` method with the input string and adds either the result or error message to the text view. Finally, the text view is scrolled to the bottom.

```lua
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
```

## REPL

Since Lua is an interpreted language, it can evaluate new chunks of code at runtime. As seen below, Lua provides a few utilities to accomplish this:

```lua
function repl:eval(chunk)
    local func, err = loadstring(chunk)

    local ret = nil
    if func then
        local results = { pcall(func) }
        if results[1] then
            ret = tostring(results[2])
            for i = 3, #results do
                ret = ret .. ", " .. tostring(results[i])
            end
        else
            err = results[2]
        end
    end

    return ret, err
end
```

The `loadstring` function will take a string, compile it to bytecode, and return a function to run this bytecode. If there is a compilation error the returned function is nil, and the second returned argument is an error string.

Since user entered code may have mistakes or errors that could cause a crash, we will run the compiled function in a protected environment, with the `pcall` function. This is Lua's equivalent of Python's `try` and `except`.

On success `pcall` returns `true`, then some number of return arguments from the compiled function. On failure `pcall` returns `false` then an error message. Since we don't know how many arguments the user's code will return, we collect all the return arguments into a table so we can count and iterate over them. On success, we concatenate all of the compiled function's return arguments into a comma-separated string to print to the text view area.

Only values returned by the compiled function will be printed to the text output. Code such as `a = 1` or `2 + 3` will not produce a printed output. Explicitly returning an expression with `a = 1 return a` or `return 2 + 3` will print the intended output.

## Packaging

Now we have a fully functional LuaREPL app. Let's package everything into a MacOS app bundle. This is actually easy to do manually. MacOS apps are just directories and files within a top level directory that ends in `.app`. Here's our app:

<img width="360" alt="Screenshot 2024-01-21 at 10 28 24" src="https://github.com/mogenson/lua-macos-app/assets/900731/789f3566-2e7c-4fe9-9837-da16be120096">

The main executable of an app goes into the `Contents/MacOS` directory and any other code or assets goes into the `Contents/Resources` directory. Finally, `Info.plist` is an xml file that sets some properties of the app, such as the name of the main executable, and app icon. This app has the absolute minimal Info.plist contents:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>main.lua</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.LuaREPL</string>
    <key>CFBundleIconFile</key>
    <string>lua</string>
</dict>
</plist>
```

## Shebang

The `Info.plist` file tells MacOS to launch main.lua when the app is opened. However, MacOS does not know the location of the `luajit` binary or how to run a Lua file. We use a neat trick to first run the `main.lua` file as a shell script, then switch to a Lua script part way through:

```lua
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
... continued ...
```

The `#!/bin/sh` line is known as a [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)) and calls `/bin/sh` to run the script. The next few lines are interpreted as shell code. The first line, `--[[` is an invalid shell command, but `2>/dev/null` silences the error message produced. The next line takes the absolute path to the `$0` argument, which is the name of the script being run, `main.lua`, appends the relative path `../Resources`, and sets the `resources` variable. The next line sets the `LUA_PATH` environmental variable using the previously defined `resources` variable. Lua searches `LUA_PATH` for modules to load when require is called to load a Lua module (like `objc.lua`). This means that no matter where our app is located, Lua will be able to load modules from the apps Resources directory. Finally, the next line replaces the shell process with an invocation of `luajit`, at the path `../Resources/luajit`, passing the name of the `main.lua` file, and using `$@` to pass any extra command line arguments.

Now `luajit` runs the `main.lua` file starting from the top again. The `#!/bin/sh` line is ignored by Lua, and the following shell code is wrapped in a multi-line Lua comment via `--[[` `]]--` so it is not evaluated. The rest of the `main.lua` file is regular Lua that starts our app!

## Conclusion

Thanks for following along with this journey to create a MacOS app using only Lua. If you have an Apple Silicon computer, you should be able to clone and run the app directly from the GitHub repo. Intel Mac users will need to rebuild `luajit` for their architecture. As far as I know there's no way to build `luajit` as a universal binary since it includes hand crafted assembly.

But, maybe we could include an x86 and am64 version of luajit and detect which interpreter to call in the shebang startup script…

If you share this app with a friend, they can edit `main.lua` in a text editor and create a complete new app. No recompling or downloading developer tools necessary. Also the only dependences are the single `luajit` binary, at 609 kB, and `objc.lua`, at 286 lines. That's way smaller than bundling a Python interpreter and all of the required modules!

I'd like to thank the authors of [fjolnir/TLC](https://github.com/fjolnir/TLC) and and [luapower/objc](https://github.com/luapower/objc) for their Objective-C Lua implementations. Unfortunately neither of these projects still run on modern versions of MacOS, but their designs and ideas were immensely helpful.

Where to next? Using the Lua to Objective-C approach from this article, we can use any part of Apple's frameworks. This app could be ported to run on an iPhone or iPad with [UIKit](https://developer.apple.com/documentation/uikit?language=objc), or we could add GPU accelerated graphics with the [Metal](https://developer.apple.com/documentation/metal/metal_sample_code_library/rendering_a_scene_with_deferred_lighting_in_objective-c?language=objc) framework!

## Appendix

There are two other pieces of the Objective-C runtime that are no longer fully functional on modern versions of MacOS: protocols and bridgesupport.

A protocol is a set of methods a delegate should implement. You can lookup a protocol via name with `objc_getProtocol` and get type information for a method, similar to how we can lookup a method from a class or object in `msgSend`. Unfortunately, Objective-C will now only generate a protocol if it is used at compile time. Since we're not compiling any Objective-C code, `objc_getProtocol` returns `NULL`.

Bridgesupport files are xml files shipped with Apple frameworks that contain class names, method names, protocol methods, and type encodings. These files can be parsed to generate the correct selector name or method type encoding. However, these files have not been updated in years and now have errors and incomplete data.

The result is that for a Lua function like `addMethod`, the user needs to provide the correct Objective-C type encoding string. There's no longer a way to look this information up for an existing method at runtime.
