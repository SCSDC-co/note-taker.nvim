local notify = require("note-taker.notify")

local M = {}

M.create_file = function(path)
    local file = io.open(path, "w")

    if not file then
        notify.error("Cannot create file " .. path .. ".")
    else
        file:close()
    end
end

M.create_dir = function(path)
    vim.uv.fs_mkdir(path, 0755)
end

---@return string
M.read_file = function(path)
    local file = io.open(path, "r")

    if not file then
        return ""
    end

    local lines = ""

    for line in file:lines() do
        lines = lines .. line .. "\n"
    end

    file:close()

    return lines
end

return M
