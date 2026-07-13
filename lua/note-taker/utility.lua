local notify = require("notify")

local M = {}

M.touch = function(path)
    local file = io.open(path, "w")

    if not file then
        notify.error("Cannot create file " .. path .. ".")
    else
        file:close()
    end
end

return M
