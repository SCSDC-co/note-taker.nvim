local default_opts = require("note-taker.default_opts")
local utility = require("note-taker.utility")
local note = require("note-taker.notes")
local ui = require("note-taker.ui")

local M = {}

M.setup = function(opts)
    ---@type Opts
    M.opts = vim.tbl_deep_extend("force", default_opts, opts or {})
    M.opts.path = vim.fn.expand(M.opts.path)

    vim.uv.fs_mkdir(M.opts.path, 0755)

    local json_path = M.opts.path .. "notes.json"

    if not vim.uv.fs_stat(json_path) then
        utility.create_file(json_path)
    end

    local json_decoded = vim.json.decode(utility.read_file(json_path))

    for _, value in ipairs(json_decoded.notes) do
        table.insert(note.notes, note.to_note(value))
    end
end

M.show_notes = function()
    ui.select_note(note.notes)
end

return M
