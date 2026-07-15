local Menu = require("nui.menu")
local event = require("nui.utils.autocmd").event
local notify = require("note-taker.notify")

local M = {}

---@param notes Note[]
M.select_note = function(notes)
    local footer = " a: Create Note "

    local notes_titles = {}

    local longest = string.len(footer)

    for _, note in ipairs(notes) do
        local note_string = (note.title .. " - " .. note.short_desc)
        local note_string_length = string.len(note_string)

        table.insert(notes_titles, Menu.item(note_string))

        if note_string_length > longest then
            longest = note_string_length
        end
    end

    local menu = Menu({
        relative = "editor",
        position = "50%",
        size = {
            width = longest,
            height = #notes,
        },
        border = {
            style = "rounded",
            text = {
                top = " Notes ",
                top_align = "center",
                bottom = footer,
                bottom_align = "right",
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
            notify.info("Note selected: " .. item.text)
        end,
    })

    return menu
end

return M
