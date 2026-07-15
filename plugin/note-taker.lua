local note_taker = require("note-taker")

vim.api.nvim_create_user_command("Note", function(opts)
    if opts.args == "list" then
        note_taker.show_notes()
    elseif opts.args == "new" then
        note_taker.create_note()
    elseif opts.args == "remove" then
        note_taker.remove_notes()
    end
end, {
    nargs = 1,

    complete = function(ArgLead, CmdLine, CursorPos)
        return { "new", "list", "remove" }
    end,
})
