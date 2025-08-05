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

markit.nvim enhances marks experience in neovim, making it easier to navigate and manage marks across projects.

## ✨ Features

- View marks in the sign column
- Add, delete, and toggle marks
- Cycle between marks
- Preview marks in floating windows
- Extract marks to quickfix/location list
- Set bookmarks with sign/virtual text annotations
- Quick navigation across buffers
- PickMe.nvim integration for marks and bookmarks with multiple picker support

## ⚡ Setup

### ⚙️ Requirements

- Neovim >= 0.6.0
- pickme.nvim (for picker integration)

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
  -- whether to map keybinds or not. default true
  default_mappings = true,
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
  -- marks.nvim allows you to configure up to 10 bookmark groups, each with its own
  -- sign/virttext. Bookmarks can be used to group together positions and quickly move
  -- across multiple buffers. default sign is '!@#$%^&*()' (from 0 to 9), and
  -- default virt_text is "".
  bookmark_0 = {
    sign = "⚑",
    virt_text = "hello world",
    -- explicitly prompt for a virtual line annotation when setting a bookmark from this group.
    -- defaults to false.
    annotate = false,
  },
  mappings = {}
}
```

## 🚀 Usage

### Mappings

The following default mappings are included:

```
    mx              Set mark x
    m,              Set the next available alphabetical (lowercase) mark
    m;              Toggle the next available mark at the current line
    dmx             Delete mark x
    dm-             Delete all marks on the current line
    dm<space>       Delete all marks in the current buffer
    m]              Move to next mark
    m[              Move to previous mark
    m:              Preview mark. This will prompt you for a specific mark to
                    preview; press <cr> to preview the next mark.
    Mx              Toggle mark x
    m[0-9]          Add a bookmark from bookmark group[0-9].
    dm[0-9]         Delete all bookmarks from bookmark group[0-9].
    m}              Move to the next bookmark having the same type as the bookmark under
                    the cursor. Works across buffers.
    m{              Move to the previous bookmark having the same type as the bookmark under
                    the cursor. Works across buffers.
    dm=             Delete the bookmark under the cursor.
```

Set `default_mappings = false` in the setup function if you don't want to have these mapped.

You can change the keybindings by setting the `mapping` table in the setup function:

```lua
require('markit').setup {
    mappings = {
        set = 'M',
        toggle_mark = 'm',
        set_next = false -- pass false to disable only this default mapping
    },
}
```

The following keys are available to be passed to the mapping table:

```
  set_next               Set next available lowercase mark at cursor.
  toggle                 Toggle next available mark at cursor.
  toggle_mark            Toggle a mark at the current line.
  delete_line            Deletes all marks on current line.
  delete_buf             Deletes all marks in current buffer.
  next                   Goes to next mark in buffer.
  prev                   Goes to previous mark in buffer.
  preview                Previews mark (will wait for user input). press <cr> to just preview the next mark.
  set                    Sets a letter mark (will wait for input).
  delete                 Delete a letter mark (will wait for input).
  set_bookmark[0-9]      Sets a bookmark from group[0-9].
  delete_bookmark[0-9]   Deletes all bookmarks from group[0-9].
  delete_bookmark        Deletes the bookmark under the cursor.
  next_bookmark          Moves to the next bookmark having the same type as the
                         bookmark under the cursor.
  prev_bookmark          Moves to the previous bookmark having the same type as the
                         bookmark under the cursor.
  next_bookmark[0-9]     Moves to the next bookmark of the same group type. Works by
                         first going according to line number, and then according to buffer
                         number.
  prev_bookmark[0-9]     Moves to the previous bookmark of the same group type. Works by
                         first going according to line number, and then according to buffer
                         number.
  annotate               Prompts the user for a virtual line annotation that is then placed
                         above the bookmark. Requires neovim 0.6+ and is not mapped by default.
```

### Keybindings

By default, these are the configured keybindings.

| Keybinding        | Command                                                  | Description                      |
| ----------------- | -------------------------------------------------------- | -------------------------------- |
| `<leader>mm`      | `:lua require("markit").marks_list_all()<cr>`            | All Marks                        |
| `<leader>mM`      | `:lua require("markit").marks_list_buf()<cr>`            | Buffer Marks                     |
| `<leader>ms`      | `:lua require("markit").set_next()<cr>`                  | Set Next Available Mark          |
| `<leader>mS`      | `:lua require("markit").set()<cr>`                       | Set Mark (Interactive)           |
| `<leader>mt`      | `:lua require("markit").toggle()<cr>`                    | Toggle Mark at Cursor            |
| `<leader>mT`      | `:lua require("markit").toggle_mark()<cr>`               | Toggle Mark (Interactive)        |
| `<leader>mj`      | `:lua require("markit").next()<cr>`                      | Next Mark                        |
| `<leader>mk`      | `:lua require("markit").prev()<cr>`                      | Previous Mark                    |
| `<leader>mP`      | `:lua require("markit").preview()<cr>`                   | Preview Mark                     |
| `<leader>md`      | `:lua require("markit").delete_line()<cr>`               | Delete Marks In Line             |
| `<leader>mD`      | `:lua require("markit").delete_buf()<cr>`                | Delete Marks In Buffer           |
| `<leader>mX`      | `:lua require("markit").delete()<cr>`                    | Delete Mark (Interactive)        |
| `<leader>mb`      | `:lua require("markit").bookmarks_list_all()<cr>`        | All Bookmarks                    |
| `<leader>mx`      | `:lua require("markit").delete_bookmark()<cr>`           | Delete Bookmark at Cursor        |
| `<leader>ma`      | `:lua require("markit").annotate()<cr>`                  | Annotate Bookmark                |
| `<leader>ml`      | `:lua require("markit").next_bookmark()<cr>`             | Next Bookmark                    |
| `<leader>mh`      | `:lua require("markit").prev_bookmark()<cr>`             | Previous Bookmark                |
| `<leader>mv`      | `:lua require("markit").toggle_signs()<cr>`              | Toggle Signs                     |
| `<leader>mqm`     | `:MarksQFListAll<cr>`                                    | All Marks → QuickFix             |
| `<leader>mqb`     | `:BookmarksQFListAll<cr>`                                | All Bookmarks → QuickFix         |
| `<leader>mqM`     | `:MarksQFListBuf<cr>`                                    | Buffer Marks → QuickFix          |
| `<leader>mqg`     | `:MarksQFListGlobal<cr>`                                 | Global Marks → QuickFix          |
| `<leader>m[0-9]`  | `:lua require("markit").toggle_bookmark[0-9]()<cr>`      | Toggle Group [0-9] Bookmark      |
| `<leader>mn[0-9]` | `:lua require("markit").next_bookmark[0-9]()<cr>`        | Next Group [0-9] Bookmark        |
| `<leader>mp[0-9]` | `:lua require("markit").prev_bookmark[0-9]()<cr>`        | Previous Group [0-9] Bookmark    |
| `<leader>mg[0-9]` | `:lua require("markit").bookmarks_list_group([0-9])<cr>` | Group [0-9] Bookmarks            |
| `<leader>mq[0-9]` | `:BookmarksQFList [0-9]<cr>`                             | Group [0-9] Bookmarks → QuickFix |

I recommend customizing these keybindings based on your preferences.

See `:help markit` for more information.

### Builtin Marks

The `builtin_marks` option allows you to track and show vim's builtin marks in the sign column. These marks will update automatically when the cursor moves.

Supported builtin marks:

- `"'"` - Last jump
- `"^"` - Last insertion stop position
- `"."` - Last change
- `"<"` - Start of last visual selection
- `">"` - End of last visual selection

### Bookmarks

Bookmarks are unnamed markers tied to a particular (buffer, line, col) triple. Unlike regular marks, bookmarks can have signs or virtual text annotations attached to them. They are useful for remembering positions across buffers without using uppercase marks.

For example, you might set two bookmarks to quickly toggle back and forth between a function and its corresponding unit test in another file.

markit.nvim supports up to 10 bookmark groups (0-9), each with its own optional sign text and virtual text annotations.

### Commands

markit.nvim defines the following commands:

- `:MarksToggleSigns[ buffer]` Toggle signs globally. Also accepts an optional buffer number to toggle signs for that buffer only.

- `:MarksListBuf` Open picker with all marks in the current buffer.

- `:MarksListGlobal` Open picker with all global marks in open buffers.

- `:MarksListAll` Open picker with all marks in all open buffers.

- `:BookmarksList [group_number]` Open picker with bookmarks. If group_number is provided, shows only that group's bookmarks, otherwise shows all bookmarks.

- `:BookmarksListAll` Open picker with all bookmarks, across all groups.

There are also corresponding commands for those who prefer the quickfix list:

- `:MarksQFListBuf`
- `:MarksQFListGlobal`
- `:MarksQFListAll`
- `:BookmarksQFList group_number`
- `:BookmarksQFListAll`

### Highlights

markit.nvim defines the following highlight groups:

- `MarkSignHL` The highlight group for displayed mark signs.
- `MarkSignNumHL` The highlight group for the number line in a signcolumn.
- `MarkSignLineHL` The highlight group for the whole line the sign is placed in.
- `MarkVirtTextHL` The highlight group for bookmark virtual text annotations.

### PickMe.nvim Integration

markit.nvim integrates with pickme.nvim to provide a fuzzy picker interface for marks and bookmarks. This gives you access to multiple picker backends (telescope, snacks, fzf-lua) based on your preference.

You can use the following API functions to list marks and bookmarks in a picker:

```lua
require('markit').marks_list_buf() -- List buffer marks
require('markit').marks_list_all() -- List all marks
require('markit').bookmarks_list_all() -- List all bookmarks
require('markit').bookmarks_list_group(1) -- List group 1 bookmarks
```

The picker will show a preview of the file content around the marked line and allow you to quickly navigate to any mark or bookmark by selecting it.

## 🏗️ What's Next

### ✅ To-Do

- [x] PickMe.nvim integration for multiple picker backends
- [ ] Enhanced preview functionality
- [ ] Custom notes for bookmarks
- [ ] Export bookmarks as md - like a trace report with links

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
