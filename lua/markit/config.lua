local M = {}

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
---@field bookmark_0 table : Configuration for bookmark group 0
---@field bookmark_1 table : Configuration for bookmark group 1
---@field bookmark_2 table : Configuration for bookmark group 2
---@field bookmark_3 table : Configuration for bookmark group 3
---@field bookmark_4 table : Configuration for bookmark group 4
---@field bookmark_5 table : Configuration for bookmark group 5
---@field bookmark_6 table : Configuration for bookmark group 6
---@field bookmark_7 table : Configuration for bookmark group 7
---@field bookmark_8 table : Configuration for bookmark group 8
---@field bookmark_9 table : Configuration for bookmark group 9
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
        bookmark = 20
    },

    cyclic = true,
    force_write_shada = false,
    refresh_interval = 150,

    excluded_filetypes = {},
    excluded_buftypes = {},

    bookmark_0 = {
        sign = ')',
        virt_text = '',
        annotate = false,
    },
    bookmark_1 = {
        sign = '!',
        virt_text = '',
        annotate = false,
    },
    bookmark_2 = {
        sign = '@',
        virt_text = '',
        annotate = false,
    },
    bookmark_3 = {
        sign = '#',
        virt_text = '',
        annotate = false,
    },
    bookmark_4 = {
        sign = '$',
        virt_text = '',
        annotate = false,
    },
    bookmark_5 = {
        sign = '%',
        virt_text = '',
        annotate = false,
    },
    bookmark_6 = {
        sign = '^',
        virt_text = '',
        annotate = false,
    },
    bookmark_7 = {
        sign = '&',
        virt_text = '',
        annotate = false,
    },
    bookmark_8 = {
        sign = '*',
        virt_text = '',
        annotate = false,
    },
    bookmark_9 = {
        sign = '(',
        virt_text = '',
        annotate = false,
    },
}

M.setup = function(opts)
    M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

return M
