local default_opts = require("note-taker.default_opts")
local utility = require("note-taker.utility")
local notify = require("note-taker.notify")

local M = {}

---@class Note
---@field title string
---@field short_desc string
---@field path string
local Note = {
    title = "",
    short_desc = "",
    path = "",
}

---@type Note[]
local notes = {}

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

    notify.info(tostring(json_decoded))
end

return M
