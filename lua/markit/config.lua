local M = {}

---@class MarkitMarkIcons
---@field buffer string
---@field default string
---@field global string
---@field last_change string
---@field last_insert string
---@field last_jump string
---@field numbered string
---@field visual_end string
---@field visual_start string

---@class MarkitIcons
---@field content_separator string
---@field default_bookmark string
---@field error string
---@field file string
---@field line_separator string
---@field target string
---@field marks MarkitMarkIcons

---@class MarkitBookmark
---@field sign string : Sign character to display (empty string to disable)
---@field virt_text string : Virtual text to show at end of line
---@field annotate boolean : Whether to prompt for annotation when setting bookmark

---@class MarkitPreviewOptions
---@field context_before integer : How many lines to show before marked line
---@field context_after integer : How many lines to show after marked line

---@class MarkitConfig
---@field add_default_keybindings boolean : Whether to add comprehensive default keybindings
---@field builtin_marks table : Which builtin marks to show in sign column
---@field cyclic boolean : Whether movements cycle back to beginning/end of buffer
---@field force_write_shada boolean : Whether the shada file is updated after modifying uppercase marks
---@field refresh_interval integer : How often (in ms) to redraw signs/recompute mark positions
---@field sign_priority table|integer : Sign priorities for different mark types
---@field excluded_filetypes table : Filetypes to disable mark tracking for
---@field excluded_buftypes table : Buffer types to disable mark tracking for
---@field signs boolean : Whether to show signs in sign column
---@field bookmarks MarkitBookmark[] : Array of bookmark group configurations
---@field preview MarkitPreviewOptions : Config options for markit preview
---@field icons MarkitIcons : List of icons used by Markit

M.config = {
    add_default_keybindings = true,

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

    preview = {
        context_before = 10,
        context_after = 20,
    },

    icons = {
        content_separator = '─',
        default_bookmark = ' ',
        error = ' ',
        file = ' ',
        line_separator = ' │',
        target = ' ',
        marks = {
            buffer = ' ',
            default = ' ',
            global = ' ',
            last_change = ' ',
            last_insert = ' ',
            last_jump = ' ',
            numbered = ' ',
            visual_end = ' ',
            visual_start = ' ',
        },
    },

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
