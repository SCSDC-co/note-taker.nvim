local Menu = require("nui.menu")
local event = require("nui.utils.autocmd").event

local M = {}

---@param notes Note[]
M.select_note = function(notes)
    local notes_titles = {}

    local longest = string.len(notes[1].title .. " - " .. notes[1].short_desc)

    for _, note in ipairs(notes) do
        local note_string = (note.title .. " - " .. note.short_desc)
        local note_string_length = string.len(note_string)

        table.insert(notes_titles, Menu.item(note_string))

        if note_string_length > longest then
            longest = note_string_length
        end
    end

    local menu = Menu({
        position = "50%",
        size = {
            width = longest,
            height = 5,
        },
        border = {
            style = "rounded",
            text = {
                top = " Notes ",
                top_align = "center",
            },
        },
        win_options = {
            winhighlight = "Normal:Normal,FloatBorder:Normal",
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
        on_close = function() end,
        on_submit = function(item)
            vim.print("You selected: ", item.text)
        end,
    })

    menu:mount()
end

return M
