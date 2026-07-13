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

    if not vim.uv.fs_stat(M.opts.path) then
        utility.touch(M.opts.path)
    end

    local json_decoded = vim.json.decode(vim.fn.readblob(M.opts.path))

    notify.info(json_decoded)
end

return M
