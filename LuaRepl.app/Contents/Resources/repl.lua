local repl = { buffer = "" }

---evaluate a chunk of lua code
---@param text string code chunk
---@return string | nil result returned values of chunk in comma separated string
---@return string | nil error message if eval failed
function repl:eval(text)
    local chunk = self.buffer .. text

    local func, err = loadstring(chunk)

    -- check if multi-line or expression
    if err and err:match("<eof>%p*$") then
        self.buffer = chunk .. "\n"
        err = nil
    end

    local ret = nil
    if func then
        self.buffer = ""
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

return repl
