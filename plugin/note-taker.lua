local note_taker = require("note-taker")

vim.api.nvim_create_user_command("Note", function()
    note_taker.show_notes()
end, {})
