local mark = require('markit.mark')
local bookmark = require('markit.bookmark')
local utils = require('markit.utils')
local commands = require('markit.commands')
local picker = require('markit.picker')

local M = {}

function M.set()
    local err, input = pcall(function()
        return string.char(vim.fn.getchar())
    end)
    if not err then
        return
    end

    if utils.is_valid_mark(input) then
        if not M.excluded_fts[vim.bo.ft] and not M.excluded_bts[vim.bo.bt] then
            M.mark_state:place_mark_cursor(input)
        end
        vim.cmd('normal! m' .. input)
    end
end

function M.set_next()
    if not M.excluded_fts[vim.bo.ft] and not M.excluded_bts[vim.bo.bt] then
        M.mark_state:place_next_mark_cursor()
    end
end

function M.toggle()
    if not M.excluded_fts[vim.bo.ft] and not M.excluded_bts[vim.bo.bt] then
        M.mark_state:toggle_mark_cursor()
    end
end

function M.toggle_mark()
    local err, input = pcall(function()
        return string.char(vim.fn.getchar())
    end)
    if not err then
        return
    end

    if utils.is_valid_mark(input) then
        if not M.excluded_fts[vim.bo.ft] then
            M.mark_state:toggle_mark(input)
        end
    end
end

function M.delete()
    local err, input = pcall(function()
        return string.char(vim.fn.getchar())
    end)
    if not err then
        return
    end

    if utils.is_valid_mark(input) then
        M.mark_state:delete_mark(input)
        return
    end
end

function M.delete_line()
    M.mark_state:delete_line_marks()
end

function M.delete_buf()
    M.mark_state:delete_buf_marks()
end

function M.delete_project()
    M.mark_state:delete_project_marks()
end

function M.delete_all()
    M.mark_state:delete_all_marks()
end

function M.preview()
    M.mark_state:preview_mark()
end

function M.next()
    M.mark_state:next_mark()
end

function M.prev()
    M.mark_state:prev_mark()
end

function M.annotate()
    M.bookmark_state:annotate()
end

function M.refresh(force_reregister)
    if M.excluded_fts[vim.bo.ft] or M.excluded_bts[vim.bo.bt] then
        return
    end

    force_reregister = force_reregister or false
    M.mark_state:refresh(nil, force_reregister)
    if M.bookmark_state then
        M.bookmark_state:refresh()
    end
end

function M._on_delete()
    local bufnr = tonumber(vim.fn.expand('<abuf>'))

    if not bufnr then
        return
    end

    M.mark_state.buffers[bufnr] = nil
    if M.bookmark_state then
        for _, group in pairs(M.bookmark_state.groups) do
            group.marks[bufnr] = nil
        end
    end
end

function M.toggle_signs(bufnr)
    if not bufnr then
        M.mark_state.opt.signs = not M.mark_state.opt.signs
        M.bookmark_state.opt.signs = not M.bookmark_state.opt.signs

        for buf, _ in pairs(M.mark_state.opt.buf_signs) do
            M.mark_state.opt.buf_signs[buf] = M.mark_state.opt.signs
        end

        for buf, _ in pairs(M.bookmark_state.opt.buf_signs) do
            M.bookmark_state.opt.buf_signs[buf] = M.bookmark_state.opt.signs
        end
    else
        M.mark_state.opt.buf_signs[bufnr] =
            not utils.option_nil(M.mark_state.opt.buf_signs[bufnr], M.mark_state.opt.signs)
        M.bookmark_state.opt.buf_signs[bufnr] =
            not utils.option_nil(M.bookmark_state.opt.buf_signs[bufnr], M.bookmark_state.opt.signs)
    end

    M.refresh(true)
end

function M.delete_bookmark()
    M.bookmark_state:delete_mark_cursor()
end

function M.next_bookmark()
    M.bookmark_state:next()
end

function M.prev_bookmark()
    M.bookmark_state:prev()
end

function M.marks_list_buf()
    picker.marks_list_buf(M.mark_state)
end

function M.marks_list_all()
    picker.marks_list_all(M.mark_state)
end

function M.marks_list_global()
    picker.marks_list_global(M.mark_state)
end

function M.marks_list_project()
    picker.marks_list_project(M.mark_state)
end

function M.bookmarks_list_all()
    picker.bookmarks_list_all(M.bookmark_state)
end

function M.bookmarks_list_buffer()
    picker.bookmarks_list_buffer(M.bookmark_state)
end

function M.bookmarks_list_project()
    picker.bookmarks_list_project(M.bookmark_state)
end

function M.bookmarks_list_group(group_nr)
    picker.bookmarks_list_group(M.bookmark_state, group_nr)
end

local function add_bookmark_commands(bookmarks)
    for i, _ in ipairs(bookmarks) do
        local group_index = i - 1
        M['set_bookmark' .. group_index] = function()
            M.bookmark_state:place_mark(group_index)
        end
        M['toggle_bookmark' .. group_index] = function()
            M.bookmark_state:toggle_mark(group_index)
        end
        M['delete_bookmark' .. group_index] = function()
            M.bookmark_state:delete_all(group_index)
        end
        M['next_bookmark' .. group_index] = function()
            M.bookmark_state:next(group_index)
        end
        M['prev_bookmark' .. group_index] = function()
            M.bookmark_state:prev(group_index)
        end
    end
end

local function assign_defaults(config)
    M.mark_state = mark.new()
    M.mark_state.builtin_marks = config.builtin_marks

    if config.enable_bookmarks then
        M.bookmark_state = bookmark.new()

        for i, bookmark_config in ipairs(config.bookmarks) do
            local group_index = i - 1
            if bookmark_config.sign == '' then
                M.bookmark_state.signs[group_index] = nil
            else
                M.bookmark_state.signs[group_index] = bookmark_config.sign
            end
            M.bookmark_state.virt_text[group_index] = bookmark_config.virt_text
            M.bookmark_state.prompt_annotate[group_index] = bookmark_config.annotate
        end

        M.bookmark_state.opt.signs = true
        M.bookmark_state.opt.buf_signs = {}
    end

    local excluded_fts = {}
    for _, ft in ipairs(config.excluded_filetypes) do
        excluded_fts[ft] = true
    end
    M.excluded_fts = excluded_fts

    local excluded_bts = {}
    for _, bt in ipairs(config.excluded_buftypes) do
        excluded_bts[bt] = true
    end
    M.excluded_bts = excluded_bts

    M.mark_state.opt.signs = config.signs
    M.mark_state.opt.buf_signs = {}
    M.mark_state.opt.force_write_shada = config.force_write_shada
    M.mark_state.opt.cyclic = config.cyclic

    M.mark_state.opt.priority = { 10, 10, 10 }
    local mark_priority = M.mark_state.opt.priority
    if type(config.sign_priority) == 'table' then
        mark_priority[1] = config.sign_priority.lower
        mark_priority[2] = config.sign_priority.upper
        mark_priority[3] = config.sign_priority.builtin
        if config.enable_bookmarks then
            M.bookmark_state.priority = config.sign_priority.bookmark
        end
    elseif type(config.sign_priority) == 'number' then
        mark_priority[1] = config.sign_priority
        mark_priority[2] = config.sign_priority
        mark_priority[3] = config.sign_priority
        if config.enable_bookmarks then
            M.bookmark_state.priority = config.sign_priority
        end
    end

    if config.enable_bookmarks then
        M.bookmark_state:load()
    end
end

function M.setup(opts)
    local config_module = require('markit.config')
    config_module.setup(opts)
    assign_defaults(config_module.config)
    if config_module.config.enable_bookmarks then
        add_bookmark_commands(config_module.config.bookmarks)
    end
    commands.setup(config_module.config)
    utils.setup_cache_handlers()
end

return M
