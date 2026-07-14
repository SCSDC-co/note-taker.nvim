local M = {}

---@class Note
---@field title string
---@field short_desc string
---@field path string

---@type Note[]
M.notes = {}

M.to_note = function(data)
    return {
        title = data.title or "",
        short_desc = data.short_desc or "",
        path = data.path or "",
    }
end

return M
