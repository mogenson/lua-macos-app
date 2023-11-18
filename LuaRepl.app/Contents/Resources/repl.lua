local repl = { buffer = "" }

function repl:eval(text) --> result, error
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
