local M = {}

M.select_note = function(notes)
    vim.ui.select(notes, {
        prompt = "Select the note to modify",
        format_item = function(item)
            return item.title
        end,
    }, function(choise)
        vim.print("You choose: " .. choise)
    end)
end

return M
