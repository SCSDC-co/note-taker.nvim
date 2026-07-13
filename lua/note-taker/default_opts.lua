---@class Opts
---@field path string
return {
    -- Where to store all the notes
    path = vim.fn.stdpath("data") .. "/note-taker/",
}
