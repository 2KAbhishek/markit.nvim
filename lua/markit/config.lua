local M = {}

---@class MarkitBookmark
---@field sign string : Sign character to display (empty string to disable)
---@field virt_text string : Virtual text to show at end of line
---@field annotate boolean : Whether to prompt for annotation when setting bookmark

---@class markit.config
---@field default_mappings boolean : Whether to map default keybinds (m, dm, etc.)
---@field add_default_keybindings boolean : Whether to add comprehensive default keybindings
---@field builtin_marks table : Which builtin marks to show in sign column
---@field cyclic boolean : Whether movements cycle back to beginning/end of buffer
---@field force_write_shada boolean : Whether the shada file is updated after modifying uppercase marks
---@field refresh_interval integer : How often (in ms) to redraw signs/recompute mark positions
---@field sign_priority table|integer : Sign priorities for different mark types
---@field excluded_filetypes table : Filetypes to disable mark tracking for
---@field excluded_buftypes table : Buffer types to disable mark tracking for
---@field signs boolean : Whether to show signs in sign column
---@field mappings table : Custom mappings to override defaults
---@field bookmarks MarkitBookmark[] : Array of bookmark group configurations (index 1-10 for groups 0-9)
M.config = {
    default_mappings = true,
    add_default_keybindings = true,
    mappings = {},

    builtin_marks = {},
    signs = true,
    sign_priority = {
        lower = 10,
        upper = 15,
        builtin = 8,
        bookmark = 20,
    },

    cyclic = true,
    force_write_shada = false,
    refresh_interval = 150,

    excluded_filetypes = {},
    excluded_buftypes = {},

    bookmarks = {
        { sign = ' ', virt_text = '', annotate = false },
        { sign = ' ', virt_text = '', annotate = false },
        { sign = ' ', virt_text = '', annotate = false },
        { sign = ' ', virt_text = '', annotate = false },
        { sign = ' ', virt_text = '', annotate = false },
        { sign = ' ', virt_text = '', annotate = false },
        { sign = ' ', virt_text = '', annotate = false },
        { sign = ' ', virt_text = '', annotate = false },
        { sign = ' ', virt_text = '', annotate = false },
        { sign = ' ', virt_text = '', annotate = false },
    },
}

M.setup = function(opts)
    M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

return M
