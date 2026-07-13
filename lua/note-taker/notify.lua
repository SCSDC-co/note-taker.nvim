local M = {}

M.info = function(msg)
    vim.notify(msg, vim.log.levels.INFO, { title = "Note Taker", icon = "" })
end

M.error = function(msg)
    vim.notify(msg, vim.log.levels.ERROR, { title = "Note Taker", icon = "" })
end

return M
