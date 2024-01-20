#!/usr/bin/env luajit

local ffi = require("ffi")
local C = ffi.C

---@alias cdata  userdata C types returned from FFI
---@alias id     cdata    Objective-C object
---@alias Class  cdata    Objective-C Class
---@alias SEL    cdata    Objective-C Selector
---@alias Method cdata    Objective-C Method

ffi.cdef([[
// types
typedef signed char   BOOL;
typedef double        CGFloat;
typedef long          NSInteger;
typedef unsigned long NSUInteger;
typedef struct objc_class    *Class;
typedef struct objc_object   *id;
typedef struct objc_selector *SEL;
typedef struct objc_method   *Method;
typedef struct objc_property *objc_property_t;
typedef id                   (*IMP) (id, SEL, ...);
typedef struct CGPoint { CGFloat x; CGFloat y; } CGPoint;
typedef struct CGSize { CGFloat width; CGFloat height; } CGSize;
typedef struct CGRect { CGPoint origin; CGSize size; } CGRect;

// API
BOOL class_addMethod(Class cls, SEL name, IMP imp, const char *types);
Class objc_allocateClassPair(Class superclass, const char *name, size_t extraBytes);
Class objc_lookUpClass(const char *name);
Class object_getClass(id obj);
Method class_getClassMethod(Class cls, SEL name);
Method class_getInstanceMethod(Class cls, SEL name);
SEL sel_registerName(const char *str);
char * method_copyArgumentType(Method m, unsigned int index);
char * method_copyReturnType(Method m);
const char * class_getName(Class cls);
const char * object_getClassName(id obj);
const char * sel_getName(SEL sel);
objc_property_t class_getProperty(Class cls, const char *name);
unsigned int method_getNumberOfArguments(Method m);
void free(void *ptr);
void objc_msgSend(void);
void objc_registerClassPair(Class cls);
]])

ffi.load("/usr/lib/libobjc.A.dylib", true)

local type_encoding = setmetatable({
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
    ["^"] = "void*",
    ["?"] = "void",
    ["r*"] = "char*",
}, {
    __index = function(_, k)
        assert(type(k) == "string" and #k > 2)
        local first_letter = k:sub(1, 1)
        if first_letter == "{" or first_letter == "(" then -- named struct or union
            return assert(select(3, k:find("%" .. first_letter .. "(%a+)=")))
        end
    end,
    __newindex = nil, -- read only table
})

---convert a NULL pointer to nil
---@param p cdata
---@return cdata | nil
local function ptr(p)
    if p == nil then return nil else return p end
end

---return a Class from name or object
---@param name string | Class
---@return Class
local function cls(name)
    assert(name)
    if ffi.istype("id", name) then
        return assert(ptr(C.object_getClass(name))) -- get class from object
    end
    if type(name) == "cdata" and ffi.istype("Class", name) then
        return name -- already a Class
    end
    assert(type(name) == "string")
    return assert(ptr(C.objc_lookUpClass(name)))
end

---return SEL from name
---@param name string | SEL
---@param num_args? integer
---@return SEL
local function sel(name, num_args)
    assert(name)
    if type(name) == "cdata" and ffi.istype("SEL", name) then
        return name -- already a SEL
    end
    assert(type(name) == "string")
    if num_args and num_args > 0 and name:sub(-1) ~= "_" then
        name = name .. "_"
    end
    local name, count = name:gsub("_", ":")
    if num_args then assert(count == num_args) end
    return C.sel_registerName(name) -- pointer is never NULL
end

---call a method for a SEL on a Class or object
---@param receiver string | Class | id
---@param selector string | SEL
---@param ...? any
---@return any
local function msgSend(receiver, selector, ...)
    ---return Method for Class or object and SEL
    ---@param receiver Class | id
    ---@param selector SEL
    ---@return Method?
    local function getMethod(receiver, selector)
        -- return method for Class or object and SEL
        if ffi.istype("Class", receiver) then
            return assert(ptr(C.class_getClassMethod(receiver, selector)))
        elseif ffi.istype("id", receiver) then
            return assert(ptr(C.class_getInstanceMethod(cls(receiver), selector)))
        end
        assert(false, "receiver not a Class or object")
    end

    ---convert a Lua variable to a C type if needed
    ---@param lua_var any
    ---@param c_type string
    ---@return cdata | any
    local function convert(lua_var, c_type)
        if type(lua_var) == "string" then
            if c_type == "SEL" then
                -- print("creating SEL from " .. lua_var)
                return sel(lua_var)
            elseif c_type == "char*" then
                -- print("creating char* from " .. lua_var)
                return ffi.cast(c_type, lua_var)
            end
        elseif type(lua_var) == "cdata" and c_type == "id" and ffi.istype("Class", lua_var) then
            -- sometimes method signatures use id instead of Class
            -- print("casting " .. tostring(lua_var) .. " to id")
            return ffi.cast(c_type, lua_var)
        end
        return lua_var -- no conversion necessary
    end

    if type(receiver) == "string" then receiver = cls(receiver) end
    local selector = sel(selector)
    local method = getMethod(receiver, selector)
    local call_args = { receiver, selector, ... }
    local char_ptr = assert(ptr(C.method_copyReturnType(method)))
    local objc_type = ffi.string(char_ptr)
    C.free(char_ptr)
    local c_type = assert(type_encoding[objc_type])
    local signature = {}
    table.insert(signature, c_type)
    table.insert(signature, "(*)(")

    local num_method_args = C.method_getNumberOfArguments(method)
    assert(num_method_args == #call_args)
    for i = 1, num_method_args do
        char_ptr = assert(ptr(C.method_copyArgumentType(method, i - 1)))
        objc_type = ffi.string(char_ptr)
        C.free(char_ptr)
        c_type = assert(type_encoding[objc_type])
        table.insert(signature, c_type)
        call_args[i] = convert(call_args[i], c_type)
        if i < num_method_args then table.insert(signature, ",") end
    end
    table.insert(signature, ")")
    local signature = table.concat(signature)

    -- print(receiver, selector, signature)
    return ffi.cast(signature, C.objc_msgSend)(unpack(call_args))
end

---load a Framework
---@param framework string
local function loadFramework(framework)
    -- on newer versions of MacOS this is a broken symbolic link, but dlopen() still succeeds
    ffi.load(string.format("/System/Library/Frameworks/%s.framework/%s", framework, framework), true)
end

local function newClass(name, super_class)
    assert(name and type(name) == "string")
    local super_class = cls(super_class or "NSObject")
    local class = assert(ptr(C.objc_allocateClassPair(super_class, name, 0)))
    C.objc_registerClassPair(class)
    return class
end

local function addMethod(class, selector, types, func)
    assert(type(func) == "function")
    assert(type(types) == "string") -- and #types - 1 == debug.getinfo(func).nparams)

    local class = cls(class)
    local selector = sel(selector)

    local signature = {}
    table.insert(signature, type_encoding[types:sub(1, 1)]) -- return type
    table.insert(signature, "(*)(")                         -- anonymous function
    for i = 2, #types do
        table.insert(signature, type_encoding[types:sub(i, i)])
        if i < #types then table.insert(signature, ",") end
    end
    table.insert(signature, ")")
    local signature = table.concat(signature)
    -- print(class, selector, signature, types)

    local imp = ffi.cast("IMP", ffi.cast(signature, func))
    assert(C.class_addMethod(class, selector, imp, types) == 1)
end


local objc = setmetatable({
    Class = cls,
    SEL = sel,
    addMethod = addMethod,
    loadFramework = loadFramework,
    msgSend = msgSend,
    newClass = newClass,
    ptr = ptr,
}, {
    __index = function(_, name)
        -- use key to lookup class by name
        return cls(name)
    end
})

ffi.metatype("struct objc_selector", {
    __tostring = function(selector)
        return ffi.string(assert(ptr(C.sel_getName(selector))))
    end
})

ffi.metatype("struct objc_class", {
    __tostring = function(class)
        return ffi.string(assert(ptr(C.class_getName(class))))
    end,
    __index = function(class, selector)
        return function(self, ...)
            assert(class == self)
            return msgSend(self, sel(selector, select("#", ...)), ...)
        end
    end
})


ffi.metatype("struct objc_object", {
    __tostring = function(class)
        return ffi.string(assert(ptr(C.object_getClassName(class))))
    end,
    __index = function(object, selector)
        if ptr(C.class_getProperty(cls(object), selector)) then
            return msgSend(object, sel(selector))
        end

        return function(self, ...)
            assert(object == self)
            return msgSend(self, sel(selector, select("#", ...)), ...)
        end
    end,
    __newindex = function(object, selector, value)
        selector = string.format('set%s%s:', selector:sub(1, 1):upper(), selector:sub(2))
        msgSend(object, sel(selector), value) -- propertyName to setPropertyName
    end
})

return objc
