local M = {}

---@param msg string
M.info = function(msg)
    vim.notify(msg, vim.log.levels.INFO, { title = "Note Taker", icon = " " })
end

---@param msg string
M.error = function(msg)
    vim.notify(msg, vim.log.levels.ERROR, { title = "Note Taker", icon = " " })
end

return M
