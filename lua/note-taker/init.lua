local default_opts = require("note-taker.default_opts")
local notify = require("note-taker.notify")
local utility = require("note-taker.utility")
local note = require("note-taker.notes")
local ui = require("note-taker.ui")
local Menu = require("nui.menu")
local Input = require("nui.input")
local event = require("nui.utils.autocmd").event

local M = {}

local PATH_COMPLETION_DELAY = 75
local PATH_COMPLETION_LIMIT = 50
local PATH_INPUT_HINT = "Tab/S-Tab: navigate | Ctrl-y: accept | Enter: create note"

local function create_input_table(text, hint)
    local width = string.len(text) + 8
    local border_text = {
        top = " " .. text .. " ",
        top_align = "center",
    }

    if hint then
        width = math.max(width, vim.fn.strdisplaywidth(hint) + 2)
        border_text.bottom = " " .. hint .. " "
        border_text.bottom_align = "center"
    end

    return {
        relative = "editor",
        position = "50%",
        size = width,
        border = {
            style = "rounded",
            text = border_text,
        },
        win_options = {
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
        },
    }
end

local function show_path_completions(input, value)
    if
        value == ""
        or not vim.api.nvim_buf_is_valid(input.bufnr)
        or not vim.api.nvim_win_is_valid(input.winid)
        or vim.api.nvim_get_current_buf() ~= input.bufnr
        or vim.fn.mode() ~= "i"
        or vim.fn.pumvisible() == 1
    then
        return
    end

    local matches = vim.fn.getcompletion(value, "file", true)

    if #matches == 0 or (#matches == 1 and matches[1] == value) then
        return
    end

    local separator_index = string.match(value, "^.*()[/\\]") or 0
    local completion_prefix = string.sub(value, 1, separator_index)

    for _, match in ipairs(matches) do
        if string.sub(match, 1, #completion_prefix) ~= completion_prefix then
            separator_index = 0
            completion_prefix = ""
            break
        end
    end

    local completion_items = {}

    for index = 1, math.min(#matches, PATH_COMPLETION_LIMIT) do
        completion_items[index] = string.sub(matches[index], #completion_prefix + 1)
    end

    vim.fn.complete(separator_index + 1, completion_items)
end

local function load_json()
    -- we need to empty the notes first, if not there will be duplicates
    note.notes = {}

    local json_decoded = vim.json.decode(utility.read_file(M.json_path))

    for _, value in ipairs(json_decoded) do
        table.insert(note.notes, note.to_note(value))
    end
end

M.setup = function(opts)
    ---@type Opts
    M.opts = vim.tbl_deep_extend("force", default_opts, opts or {})
    M.opts.path = vim.fn.expand(M.opts.path)

    if M.opts.path:sub(-1) ~= "/" then
        M.opts.path = M.opts.path + "/"
    end

    M.json_path = M.opts.path .. "notes.json"

    vim.uv.fs_mkdir(M.opts.path, tonumber("755", 8))

    if not vim.uv.fs_stat(M.json_path) then
        utility.create_file(M.json_path, {})
    end
end

M.create_note = function()
    local note_title = ""
    local note_desc = ""
    local note_path = ""
    local path_completion_request = 0
    local refresh_path_completion = false

    local input_path

    input_path = Input(create_input_table("Note Path", PATH_INPUT_HINT), {
        prompt = "",
        default_value = "",
        on_close = function() end,
        on_change = function(value)
            path_completion_request = path_completion_request + 1
            local request = path_completion_request

            vim.defer_fn(function()
                if request == path_completion_request then
                    show_path_completions(input_path, value)
                end
            end, PATH_COMPLETION_DELAY)
        end,
        on_submit = function(value)
            note_path = value

            note.add_note(
                { title = note_title, short_desc = note_desc, path = note_path, id = 0 },
                M.json_path
            )
        end,
    })

    vim.api.nvim_set_option_value("completeopt", "menuone,noselect", { buf = input_path.bufnr })

    input_path:map("i", "<Tab>", function()
        return vim.fn.pumvisible() == 1 and "<C-n>" or "<C-x><C-f>"
    end, { expr = true, noremap = true, replace_keycodes = true })

    input_path:map("i", "<S-Tab>", function()
        return vim.fn.pumvisible() == 1 and "<C-p>" or "<C-x><C-f>"
    end, { expr = true, noremap = true, replace_keycodes = true })

    input_path:map("i", "<C-y>", function()
        local completion_info = vim.fn.complete_info({ "selected" })

        refresh_path_completion = vim.fn.pumvisible() == 1 and completion_info.selected >= 0

        return "<C-y>"
    end, { expr = true, noremap = true, replace_keycodes = true })

    input_path:on({ event.CompleteDone }, function()
        if not refresh_path_completion then
            return
        end

        refresh_path_completion = false

        vim.schedule(function()
            if
                not vim.api.nvim_buf_is_valid(input_path.bufnr)
                or not vim.api.nvim_win_is_valid(input_path.winid)
            then
                return
            end

            local value = vim.api.nvim_buf_get_lines(input_path.bufnr, 0, 1, false)[1] or ""

            show_path_completions(input_path, value)
        end)
    end)

    input_path:map("n", "<Esc>", function()
        input_path:unmount()
    end, { noremap = true })

    input_path:map("n", "q", function()
        input_path:unmount()
    end, { noremap = true })

    input_path:on({ event.WinEnter }, function()
        vim.opt_local.sidescrolloff = 0
    end, { once = false })

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

    input_desc:on({ event.WinEnter }, function()
        vim.opt_local.sidescrolloff = 0
    end, { once = false })

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

    input_title:on({ event.WinEnter }, function()
        vim.opt_local.sidescrolloff = 0
    end, { once = false })

    input_title:mount()
end

M.show_notes = function()
    load_json()

    if #note.notes == 0 then
        notify.info("No notes found!")
        return
    end

    local menu = ui.select_note(note.notes)

    menu:map("n", "a", function(bufnr)
        menu:unmount()

        M.create_note()
    end)

    menu:mount()
end

M.remove_notes = function()
    load_json()

    if #note.notes == 0 then
        notify.info("No notes to remove!")
        return
    end

    local notes_titles = {}

    local longest = string.len(
        note.notes[1].id .. ". " .. note.notes[1].title .. " - " .. note.notes[1].short_desc
    )

    for _, _note in ipairs(note.notes) do
        local note_string = (_note.id .. ". " .. _note.title .. " - " .. _note.short_desc)
        local note_string_length = string.len(note_string)

        table.insert(notes_titles, Menu.item(note_string, { id = _note.id }))

        if note_string_length > longest then
            longest = note_string_length
        end
    end

    local menu = Menu({
        relative = "editor",
        position = "50%",
        size = {
            width = longest,
            height = #note.notes,
        },
        border = {
            style = "rounded",
            text = {
                top = " Notes ",
                top_align = "center",
            },
        },
        win_options = {
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
        },
    }, {
        lines = notes_titles,
        max_width = longest,
        keymap = {
            focus_next = { "j", "<Down>", "<Tab>" },
            focus_prev = { "k", "<Up>", "<S-Tab>" },
            close = { "q", "<Esc>", "<C-c>" },
            submit = { "<CR>", "<Space>" },
        },
        on_close = function()
            notify.info("Nothing selected!")
        end,
        on_submit = function(item)
            note.remove_note(item.id, M.json_path)
            load_json()
            notify.info("Note removed: " .. item.id)
        end,
    })

    menu:mount()
end

return M
