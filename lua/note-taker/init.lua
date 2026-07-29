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
local PATH_INPUT_HINT = "Tab/S-Tab: navigate | Ctrl-y: accept | Enter: continue"

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

---@param path string
---@return boolean
local function create_empty_file(path)
    local descriptor, open_error = vim.uv.fs_open(path, "wx", tonumber("644", 8))

    if not descriptor then
        notify.error("Cannot create file " .. path .. ": " .. open_error)
        return false
    end

    local success, close_error = vim.uv.fs_close(descriptor)

    if not success then
        notify.error("Cannot close file " .. path .. ": " .. close_error)
        return false
    end

    return true
end

---@param path string
---@param on_confirm fun()
local function confirm_note_path(path, on_confirm)
    local expanded_path = vim.fn.expand(path or "")

    if expanded_path == "" then
        notify.error("Note path is empty!")
        return
    end

    local absolute_path = vim.fn.fnamemodify(expanded_path, ":p")
    local file_stat, stat_error, stat_code = vim.uv.fs_stat(absolute_path)

    if not file_stat and stat_code ~= "ENOENT" then
        notify.error("Cannot access file " .. absolute_path .. ": " .. stat_error)
        return
    end

    if file_stat and file_stat.type ~= "file" then
        notify.error("Note path is not a file: " .. absolute_path)
        return
    end

    local should_create_file = file_stat == nil

    if should_create_file then
        local parent_path = vim.fs.dirname(absolute_path)
        local parent_stat = vim.uv.fs_stat(parent_path)

        if not parent_stat or parent_stat.type ~= "directory" then
            notify.error("Parent directory does not exist: " .. parent_path)
            return
        end
    end

    local confirm_choice = should_create_file and "Create file" or "Link file"
    local prompt = should_create_file and "Create this file and link it to the note?"
        or "Link this existing file to the note?"

    vim.ui.select({ confirm_choice, "Cancel" }, {
        prompt = prompt .. " " .. absolute_path,
        kind = "note-taker-confirm",
    }, function(choice)
        if choice ~= confirm_choice then
            notify.info("Note creation cancelled.")
            return
        end

        if should_create_file then
            if not create_empty_file(absolute_path) then
                return
            end
        else
            local current_stat = vim.uv.fs_stat(absolute_path)

            if not current_stat or current_stat.type ~= "file" then
                notify.error("File is no longer available: " .. absolute_path)
                return
            end
        end

        on_confirm()
    end)
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

            confirm_note_path(note_path, function()
                note.add_note(
                    { title = note_title, short_desc = note_desc, path = note_path, id = 0 },
                    M.json_path
                )

                notify.info("Note created!")
            end)
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
