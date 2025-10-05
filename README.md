<div align = "center">

<h1><a href="https://github.com/2kabhishek/markit.nvim">markit.nvim</a></h1>

<a href="https://github.com/2KAbhishek/markit.nvim/blob/main/LICENSE">
<img alt="License" src="https://img.shields.io/github/license/2kabhishek/markit.nvim?style=flat&color=eee&label="> </a>

<a href="https://github.com/2KAbhishek/markit.nvim/graphs/contributors">
<img alt="People" src="https://img.shields.io/github/contributors/2kabhishek/markit.nvim?style=flat&color=ffaaf2&label=People"> </a>

<a href="https://github.com/2KAbhishek/markit.nvim/stargazers">
<img alt="Stars" src="https://img.shields.io/github/stars/2kabhishek/markit.nvim?style=flat&color=98c379&label=Stars"></a>

<a href="https://github.com/2KAbhishek/markit.nvim/network/members">
<img alt="Forks" src="https://img.shields.io/github/forks/2kabhishek/markit.nvim?style=flat&color=66a8e0&label=Forks"> </a>

<a href="https://github.com/2KAbhishek/markit.nvim/watchers">
<img alt="Watches" src="https://img.shields.io/github/watchers/2kabhishek/markit.nvim?style=flat&color=f5d08b&label=Watches"> </a>

<a href="https://github.com/2KAbhishek/markit.nvim/pulse">
<img alt="Last Updated" src="https://img.shields.io/github/last-commit/2kabhishek/markit.nvim?style=flat&color=e06c75&label="> </a>

<h3>Better marks for Neovim 🏹📌</h3>

<figure>
  <img src="images/screenshot.png" alt="markit.nvim in action">
  <br/>
  <figcaption>markit.nvim in action</figcaption>
</figure>

</div>

markit.nvim enhances marks experience in neovim, making it easier to mark and navigate to specific lines of code in your projects.

## ✨ Features

- Quickly manage and navigate marks across your entire codebase with an intuitive commands.
- Set persistent bookmarks with visual sign/virtual text annotations, organized into customizable groups
- Seamless picker integrations via pickme.nvim for fuzzy searching and quick access to your marks/bookmarks.
- View marks and bookmarks in the sign column with customizable priorities and highlight groups.
- Cycle between marks and bookmarks within buffers or across your entire project with git-aware scoping.
- Preview marks in floating windows to see context before jumping, with enhanced file content display.
- Extract marks and bookmarks to quickfix lists for batch operations and integration with other tools.

## ⚡ Setup

### ⚙️ Requirements

- Neovim >= 0.6.0
- [pickme.nvim](https://github.com/2kabhishek/pickme.nvim) (for picker integration)

### 💻 Installation

With lazy.nvim

```lua
{
    '2kabhishek/markit.nvim',
    dependencies = { '2kabhishek/pickme.nvim' },
    config = load_config('tools.marks'),
    event = { 'BufReadPre', 'BufNewFile' },
},
```

### 🛠️ Configuration

```lua
require('markit').setup {
  -- whether to add comprehensive default keybindings. default true
  add_default_keybindings = true,
  -- which builtin marks to show. default {}
  builtin_marks = { ".", "<", ">", "^" },
  -- whether movements cycle back to the beginning/end of buffer. default true
  cyclic = true,
  -- whether the shada file is updated after modifying uppercase marks. default false
  force_write_shada = false,
  -- how often (in ms) to redraw signs/recompute mark positions.
  -- higher value means better performance but may cause visual lag,
  -- while lower value may cause performance penalties. default 150.
  refresh_interval = 150,
  -- sign priorities for each type of mark - builtin marks, uppercase marks, lowercase
  -- marks, and bookmarks.
  -- can be either a table with all/none of the keys, or a single number, in which case
  -- the priority applies to all marks.
  -- default 10.
  sign_priority = { lower=10, upper=15, builtin=8, bookmark=20 },
  -- disables mark tracking for specific filetypes. default {}
  excluded_filetypes = {},
  -- disables mark tracking for specific buftypes. default {}
  excluded_buftypes = {},
  -- whether to enable the bookmark system. when disabled, improves startup performance, default true
  enable_bookmarks = true,
  -- bookmark groups configuration (only used when enable_bookmarks = true)
  bookmarks = {
    {
      sign = "⚑",           -- string: sign character to display (empty string to disable)
      virt_text = "hello",  -- string: virtual text to show at end of line
      annotate = false      -- boolean: whether to prompt for annotation when setting bookmark
    },
    { sign = "!", virt_text = "", annotate = false },
    { sign = "@", virt_text = "", annotate = true },
  },
}
```

## 🚀 Usage

### Commands

markit.nvim provides a unified hierarchical command system for all functionality:

#### Mark Commands

| Command                                  | Description                                      |
| ---------------------------------------- | ------------------------------------------------ |
| `Markit mark list [scope]`               | List marks (scope: buffer, project, all)         |
| `Markit mark list quickfix [scope]`      | Send marks to quickfix                           |
| `Markit mark toggle [mark_char]`         | Toggle mark at cursor                            |
| `Markit mark set [mark_char]`            | Set mark at cursor                               |
| `Markit mark delete [scope] [mark_char]` | Delete marks (scope: line, buffer, project, all) |
| `Markit mark next`                       | Go to next mark                                  |
| `Markit mark prev`                       | Go to previous mark                              |
| `Markit mark goto <mark_char>`           | Go to specific mark                              |
| `Markit mark preview`                    | Preview mark in floating window                  |

#### Bookmark Commands

| Command                                  | Description                                          |
| ---------------------------------------- | ---------------------------------------------------- |
| `Markit bookmark list [scope]`           | List bookmarks (scope: buffer, project, all, 0-9)    |
| `Markit bookmark list quickfix [scope]`  | Send bookmarks to quickfix                           |
| `Markit bookmark toggle [group]`         | Toggle bookmark at cursor (group: 0-9)               |
| `Markit bookmark annotate`               | Annotate bookmark at cursor                          |
| `Markit bookmark delete [scope] [group]` | Delete bookmarks (scope: line, buffer, project, all) |
| `Markit bookmark next [group]`           | Go to next bookmark (group: 0-9)                     |
| `Markit bookmark prev [group]`           | Go to previous bookmark (group: 0-9)                 |
| `Markit bookmark goto <group>`           | Go to specific bookmark group (0-9)                  |
| `Markit bookmark signs [buffer]`         | Toggle signs display for buffer                      |

### Command Scopes

The unified command system supports different scopes for filtering marks and bookmarks:

- **`buffer`**: Show only marks/bookmarks in the current buffer
- **`project`**: Show marks/bookmarks within the current git repository (uses `git rev-parse --show-toplevel`)
- **`all`**: Show all marks/bookmarks across all buffers
- **`0-9`**: (Bookmarks only) Show bookmarks from a specific group

**Examples:**

```vim
" Mark operations
:Markit mark list project          " List all marks in current git repo
:Markit mark set a                 " Set mark 'a' at cursor
:Markit mark toggle                " Toggle mark at cursor (next available)
:Markit mark delete buffer         " Delete all marks in current buffer
:Markit mark goto A                " Jump to global mark 'A'

" Bookmark operations
:Markit bookmark list buffer       " List bookmarks in current buffer
:Markit bookmark toggle 0          " Toggle bookmark group 0 at cursor
:Markit bookmark list 2            " List bookmarks from group 2
:Markit bookmark delete project    " Delete all bookmarks in git repo
:Markit bookmark signs             " Toggle bookmark signs display

" Quickfix integration
:Markit mark list quickfix all     " Send all marks to quickfix list
:Markit bookmark list quickfix 1   " Send group 1 bookmarks to quickfix
```

### Keybindings

By default, these are the configured keybindings using the unified command structure:

| Keybinding        | Command                                    | Description                      |
| ----------------- | ------------------------------------------ | -------------------------------- |
| `<leader>mm`      | `:Markit mark list all<cr>`                | All Marks                        |
| `<leader>mM`      | `:Markit mark list buffer<cr>`             | Buffer Marks                     |
| `<leader>ms`      | `:Markit mark set<cr>`                     | Set Next Available Mark          |
| `<leader>mS`      | `:Markit mark set<cr>`                     | Set Mark (Interactive)           |
| `<leader>mt`      | `:Markit mark toggle<cr>`                  | Toggle Mark at Cursor            |
| `<leader>mT`      | `:Markit mark toggle<cr>`                  | Toggle Mark (Interactive)        |
| `<leader>mj`      | `:Markit mark next<cr>`                    | Next Mark                        |
| `<leader>mk`      | `:Markit mark prev<cr>`                    | Previous Mark                    |
| `<leader>mP`      | `:Markit mark preview<cr>`                 | Preview Mark                     |
| `<leader>md`      | `:Markit mark delete line<cr>`             | Delete Marks In Line             |
| `<leader>mD`      | `:Markit mark delete buffer<cr>`           | Delete Marks In Buffer           |
| `<leader>mX`      | `:Markit mark delete<cr>`                  | Delete Mark (Interactive)        |
| `<leader>mb`      | `:Markit bookmark list all<cr>`            | All Bookmarks                    |
| `<leader>mx`      | `:Markit bookmark delete<cr>`              | Delete Bookmark at Cursor        |
| `<leader>ma`      | `:Markit bookmark annotate<cr>`            | Annotate Bookmark                |
| `<leader>ml`      | `:Markit bookmark next<cr>`                | Next Bookmark                    |
| `<leader>mh`      | `:Markit bookmark prev<cr>`                | Previous Bookmark                |
| `<leader>mv`      | `:Markit bookmark signs<cr>`               | Toggle Signs                     |
| `<leader>mqm`     | `:Markit mark list quickfix all<cr>`       | All Marks → QuickFix             |
| `<leader>mqb`     | `:Markit bookmark list quickfix all<cr>`   | All Bookmarks → QuickFix         |
| `<leader>mqM`     | `:Markit mark list quickfix buffer<cr>`    | Buffer Marks → QuickFix          |
| `<leader>mqg`     | `:Markit mark list quickfix all<cr>`       | All Marks → QuickFix             |
| `<leader>m[0-9]`  | `:Markit bookmark toggle [0-9]<cr>`        | Toggle Group [0-9] Bookmark      |
| `<leader>mn[0-9]` | `:Markit bookmark next [0-9]<cr>`          | Next Group [0-9] Bookmark        |
| `<leader>mp[0-9]` | `:Markit bookmark prev [0-9]<cr>`          | Previous Group [0-9] Bookmark    |
| `<leader>mc[0-9]` | `:Markit bookmark delete [0-9]<cr>`        | Delete Group [0-9] Bookmarks     |
| `<leader>mg[0-9]` | `:Markit bookmark list [0-9]<cr>`          | Group [0-9] Bookmarks            |
| `<leader>mq[0-9]` | `:Markit bookmark list quickfix [0-9]<cr>` | Group [0-9] Bookmarks → QuickFix |

I recommend customizing these keybindings based on your preferences.

See `:help markit` for more information.

### Builtin Marks

The `builtin_marks` option allows you to track and show vim's builtin marks in the sign column. These marks will update automatically when the cursor moves.

Supported builtin marks:

- `'` - Last jump
- `^` - Last insertion stop position
- `.` - Last change
- `<` - Start of last visual selection
- `>` - End of last visual selection

### Bookmarks

Bookmarks are unnamed markers tied to a particular (buffer, line, col) triple. Unlike regular marks, bookmarks can have signs or virtual text annotations attached to them. They are useful for remembering positions across buffers without using uppercase marks.

For example, you might set two bookmarks to quickly toggle back and forth between a function and its corresponding unit test in another file.

markit.nvim supports up to 10 bookmark groups (0-9), each with its own optional sign text and virtual text annotations.

### Highlights

markit.nvim defines the following highlight groups:

- `MarkSignHL` The highlight group for displayed mark signs.
- `MarkSignNumHL` The highlight group for the number line in a signcolumn.
- `MarkSignLineHL` The highlight group for the whole line the sign is placed in.
- `MarkVirtTextHL` The highlight group for bookmark virtual text annotations.

The picker will show a preview of the file content around the marked line and allow you to quickly navigate to any mark or bookmark by selecting it.

## 🏗️ What's Next

### ✅ To-Do

- [ ] All marks are not showing up on `Markit mark list all`
- [ ] When jumping to bookmarked files, treesitter highlighting is not applied

## ⛅ Behind The Code

### 🌈 Inspiration

This is a fork of [marks.nvim](https://github.com/chentoast/marks.nvim) with some fixes and improvements from the community.

### 🧰 Tooling

- [dots2k](https://github.com/2kabhishek/dots2k) — Dev Environment
- [nvim2k](https://github.com/2kabhishek/nvim2k) — Personalized Editor

### 🔍 More Info

- [marks.nvim](https://github.com/chentoast/marks.nvim) Inspiration and base for this project

<hr>

<div align="center">

<strong>⭐ hit the star button if you found this useful ⭐</strong><br>

<a href="https://github.com/2KAbhishek/markit.nvim">Source</a>
| <a href="https://2kabhishek.github.io/blog" target="_blank">Blog </a>
| <a href="https://twitter.com/2kabhishek" target="_blank">Twitter </a>
| <a href="https://linkedin.com/in/2kabhishek" target="_blank">LinkedIn </a>
| <a href="https://2kabhishek.github.io/links" target="_blank">More Links </a>
| <a href="https://2kabhishek.github.io/projects" target="_blank">Other Projects </a>

</div>
