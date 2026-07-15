local utility = require("note-taker.utility")

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

---@param note Note
---@param json_path string
M.add_note = function(note, json_path)
    local json_decoded = vim.json.decode(utility.read_file(json_path))

    json_decoded["notes"][#json_decoded["notes"] + 1] = note

    local new_json = vim.json.encode(json_decoded, { indent = "  " })

    local json_file = io.open(json_path, "w+")

    if json_file == nil then
        return
    end

    json_file:write(new_json)

    json_file:close()
end

return M
