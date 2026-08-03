---@class Opts
---@field path string
---@field confirm_linkage boolean
return {
    -- Where to store all the notes
    path = vim.fn.stdpath("data") .. "/note-taker/",
    -- Whether to confirm before linking an existing file or creating a missing one
    confirm_linkage = true,
}
