local utility = require("note-taker.utility")
local M = {}

---@class Note
---@field title string
---@field short_desc string
---@field path string
---@field id number

---@type Note[]
M.notes = {}

local function reload_json(json_path, text)
    local json_file = io.open(json_path, "w+")

    if json_file == nil then
        return
    end

    json_file:write(text)

    json_file:close()
end

M.to_note = function(data)
    return {
        title = data.title or "",
        short_desc = data.short_desc or "",
        path = data.path or "",
        id = data.id or 0,
    }
end

---@param note Note
---@param json_path string
M.add_note = function(note, json_path)
    local json_decoded = vim.json.decode(utility.read_file(json_path))

    note.id = #json_decoded + 1

    json_decoded[#json_decoded + 1] = note

    local new_json = vim.json.encode(json_decoded, { indent = "  " })

    reload_json(json_path, new_json)
end

---@param id number
---@param json_path string
M.remove_note = function(id, json_path)
    local json_decoded = vim.json.decode(utility.read_file(json_path))

    local final_table = {}

    for _, value in pairs(json_decoded) do
        if value["id"] ~= id then
            table.insert(final_table, value)
        end
    end

    local new_json = vim.json.encode(final_table, { indent = "  " })

    reload_json(json_path, new_json)
end

return M
