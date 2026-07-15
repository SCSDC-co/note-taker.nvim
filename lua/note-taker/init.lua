local default_opts = require("note-taker.default_opts")
local utility = require("note-taker.utility")
local note = require("note-taker.notes")
local ui = require("note-taker.ui")
local Input = require("nui.input")
local event = require("nui.utils.autocmd").event

local M = {}

local function create_input_table(text)
    return {
        relative = "editor",
        position = "50%",
        size = string.len(text) + 2,
        border = {
            style = "rounded",
            text = {
                top = " " .. text .. " ",
                top_align = "center",
            },
        },
        win_options = {
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
        },
    }
end

M.setup = function(opts)
    ---@type Opts
    M.opts = vim.tbl_deep_extend("force", default_opts, opts or {})
    M.opts.path = vim.fn.expand(M.opts.path)
    M.json_path = M.opts.path .. "notes.json"

    vim.uv.fs_mkdir(M.opts.path, 0755)

    if not vim.uv.fs_stat(M.json_path) then
        utility.create_file(M.json_path)
    end

    local json_decoded = vim.json.decode(utility.read_file(M.json_path))

    for _, value in ipairs(json_decoded.notes) do
        table.insert(note.notes, note.to_note(value))
    end
end

M.show_notes = function()
    ui.select_note(note.notes)
end

M.create_note = function()
    local note_title = ""
    local note_desc = ""
    local note_path = ""

    local input_path = Input(create_input_table("Note Path"), {
        prompt = "",
        default_value = "",
        on_close = function() end,
        on_submit = function(value)
            note_path = value
            note.add_note(
                { title = note_title, short_desc = note_desc, path = note_path },
                M.json_path
            )
        end,
    })

    input_path:map("n", "<Esc>", function()
        input_path:unmount()
    end, { noremap = true })

    input_path:map("n", "q", function()
        input_path:unmount()
    end, { noremap = true })

    local input_desc = Input(create_input_table("Note Desc"), {
        prompt = "",
        default_value = "",
        on_close = function() end,
        on_submit = function(value)
            input_path:mount()
            note_desc = value
        end,
    })

    input_desc:map("n", "<Esc>", function()
        input_desc:unmount()
    end, { noremap = true })

    input_desc:map("n", "q", function()
        input_desc:unmount()
    end, { noremap = true })

    local input_title = Input(create_input_table("Note Title"), {
        prompt = "",
        default_value = "",
        on_close = function() end,
        on_submit = function(value)
            input_desc:mount()
            note_title = value
        end,
    })

    input_title:map("n", "<Esc>", function()
        input_title:unmount()
    end, { noremap = true })

    input_title:map("n", "q", function()
        input_title:unmount()
    end, { noremap = true })

    input_title:mount()
end

return M
