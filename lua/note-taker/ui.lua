local Menu = require("nui.menu")
local event = require("nui.utils.autocmd").event

local M = {}

---@param notes Note[]
M.select_note = function(notes)
    local notes_titles = {}

    for _, note in ipairs(notes) do
        table.insert(notes_titles, Menu.item(note.title .. " - " .. note.short_desc))
    end

    local menu = Menu({
        position = "50%",
        size = {
            width = 25,
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
        max_width = 20,
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
