# Note Taker

A minimal note-taking plugin for Neovim. Notes are stored locally as JSON and
managed through floating [`nui.nvim`](https://github.com/MunifTanjim/nui.nvim)
menus.

## Requirements

- Neovim 0.10 or newer
- `nui.nvim`

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "SCSDC-co/note-taker.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    config = function()
        require("note-taker").setup()
    end,
}
```

## Configuration

By default, notes are saved in Neovim's data directory. To use another
location, provide a path ending in `/`:

```lua
require("note-taker").setup({
    path = vim.fn.expand("~/notes/"),
})
```

## Usage

| Command | Action |
| --- | --- |
| `:Note new` | Create a note by entering its title, description, and path. |
| `:Note list` | Browse saved notes. Press `a` to create another note. |
| `:Note remove` | Select and remove a saved note. |

Inside menus, use `j`/`k` or the arrow keys to move, `Enter` to select, and
`q` or `Esc` to close.

## License

GNU GPL v3. See [LICENSE](LICENSE).
