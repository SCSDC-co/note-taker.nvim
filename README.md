<!-- "You don't use HTML tags in markdown" i don't give a fuck -->
<div align=center>

# Note Taker

</div>

A minimal note-taking plugin for Neovim.
Aimed to be easy and fast to use.

> [!WARNING]
> This plugin is in its early stages of development, it can have bugs
> and features missing/incomplete

## Requirements

- Neovim 0.10 or newer
- `nui.nvim`

## Installation

- Using [vim.pack](https://neovim.io/doc/user/pack/#vim.pack):

> [!WARNING]
> You need `nvim` 0.12 or above to use `vim.pack`

```lua
vim.pack.add{
  "https://github.com/MunifTanjim/nui.nvim"
  "https://github.com/SCSDC-co/note-taker.nvim"
}
```

- Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "SCSDC-co/note-taker.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {}
}
```

- Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "SCSDC-co/note-taker.nvim",
  requires = { "MunifTanjim/nui.nvim", opt = true },
}
```

- Using [vim-plug](https://github.com/junegunn/vim-plug):

```lua
Plug "MunifTanjim/nui.nvim"
Plug "SCSDC-co/note-taker.nvim"
```

## Configuration

This is the default configuration:

```lua
require("note-taker").setup({
  path = vim.fn.stdpath("data") .. "/note-taker/",
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
