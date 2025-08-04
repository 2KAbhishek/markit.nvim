local mark = require('markit.mark')
local bookmark = require('markit.bookmark')
local utils = require('markit.utils')
local pickme = require('pickme')
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
    M.bookmark_state:refresh()
end

function M._on_delete()
    local bufnr = tonumber(vim.fn.expand('<abuf>'))

    if not bufnr then
        return
    end

    M.mark_state.buffers[bufnr] = nil
    for _, group in pairs(M.bookmark_state.groups) do
        group.marks[bufnr] = nil
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

-- set_group[0-9] functions
for i = 0, 9 do
    M['set_bookmark' .. i] = function()
        M.bookmark_state:place_mark(i)
    end
    M['toggle_bookmark' .. i] = function()
        M.bookmark_state:toggle_mark(i)
    end
    M['delete_bookmark' .. i] = function()
        M.bookmark_state:delete_all(i)
    end
    M['next_bookmark' .. i] = function()
        M.bookmark_state:next(i)
    end
    M['prev_bookmark' .. i] = function()
        M.bookmark_state:prev(i)
    end
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

-- Pickme.nvim integration functions

---Get file type icon based on file extension
---@param filepath string
---@return string icon, string? color
local function get_filetype_icon(filepath)
    if not filepath or filepath == '' then
        return ' ', nil
    end

    local ext = vim.fn.fnamemodify(filepath, ':e'):lower()
    local filename = vim.fn.fnamemodify(filepath, ':t'):lower()

    -- Try to use nvim-web-devicons if available
    local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
    if has_devicons then
        local icon, color = devicons.get_icon_color(filename, ext)
        if icon then
            return icon, color
        end
    end

    return ' ', nil
end

---Get mark type icon and description
---@param mark string
---@return string icon, string description
local function get_mark_type_info(mark)
    if not mark then
        return ' ', 'Unknown'
    end

    if mark:match('[a-z]') then
        return ' ', 'Buffer Mark'
    elseif mark:match('[A-Z]') then
        return ' ', 'Global Mark'
    elseif mark:match('[0-9]') then
        return ' ', 'Numbered Mark'
    elseif mark == "'" then
        return ' ', 'Last Jump'
    elseif mark == '^' then
        return ' ', 'Last Insert'
    elseif mark == '.' then
        return ' ', 'Last Change'
    elseif mark == '<' then
        return ' ', 'Visual Start'
    elseif mark == '>' then
        return ' ', 'Visual End'
    else
        return ' ', 'Special Mark'
    end
end

---Get bookmark group icon and color
---@param group_nr number
---@return string icon, string description
local function get_bookmark_info(group_nr)
    local icons =
        { '1️⃣', '2️⃣', '3️⃣', '4️⃣', '5️⃣', '6️⃣', '7️⃣', '8️⃣', '9️⃣', ' ' }
    local colors = { 'Red', 'Orange', 'Yellow', 'Green', 'Blue', 'Indigo', 'Violet', 'Pink', 'Cyan', 'Gray' }

    if group_nr >= 0 and group_nr <= 9 then
        return icons[group_nr + 1] or ' ', colors[group_nr + 1] or 'Default'
    end

    return ' ', 'Default'
end

---Format file path for display
---@param filepath string
---@param max_length number?
---@return string
local function format_file_path(filepath, max_length)
    if not filepath or filepath == '' then
        return '[No File]'
    end

    max_length = max_length or 30
    local relative_path = vim.fn.fnamemodify(filepath, ':.')

    -- If path is too long, show ...beginning or end...
    if #relative_path > max_length then
        local filename = vim.fn.fnamemodify(filepath, ':t')
        local dirname = vim.fn.fnamemodify(filepath, ':h:t')

        if #filename + #dirname + 1 <= max_length then
            return dirname .. '/' .. filename
        elseif #filename <= max_length - 3 then
            return '...' .. filename
        else
            return relative_path:sub(1, max_length - 3) .. '...'
        end
    end

    return relative_path
end

---Create enhanced entry for marks
---@param mark_entry table
---@return table
local function marks_entry_maker(mark_entry)
    local file_icon, file_color = get_filetype_icon(mark_entry.path)
    local mark_icon, mark_desc = get_mark_type_info(mark_entry.mark)
    local file_path = format_file_path(mark_entry.path, 25)

    -- Truncate line content if too long
    local line_content = mark_entry.line or ''
    if #line_content > 50 then
        line_content = line_content:sub(1, 47) .. '...'
    end

    -- Format: [mark_icon] mark [file_icon] line_content → file_path:line_num
    local display = string.format(
        '%s %s %s %s:%d → %s',
        mark_icon,
        mark_entry.mark,
        file_icon,
        file_path,
        mark_entry.lnum or 0,
        line_content
    )

    return {
        value = mark_entry,
        display = display,
        ordinal = mark_entry.mark .. ' ' .. line_content .. ' ' .. file_path,
        path = mark_entry.path,
        mark_type = mark_desc,
        file_icon = file_icon,
        file_color = file_color,
    }
end

---Create enhanced entry for bookmarks
---@param bookmark_entry table
---@return table
local function bookmarks_entry_maker(bookmark_entry)
    local file_icon, file_color = get_filetype_icon(bookmark_entry.path)
    local bookmark_icon, bookmark_desc = get_bookmark_info(bookmark_entry.group)
    local file_path = format_file_path(bookmark_entry.path, 25)

    -- Truncate line content if too long
    local line_content = bookmark_entry.line or ''
    if #line_content > 50 then
        line_content = line_content:sub(1, 47) .. '...'
    end

    -- Format: [bookmark_icon] group [file_icon] line_content → file_path:line_num
    local display = string.format(
        '%s %d %s %s → %s:%d',
        bookmark_icon,
        bookmark_entry.group or 0,
        file_icon,
        line_content,
        file_path,
        bookmark_entry.lnum or 0
    )

    return {
        value = bookmark_entry,
        display = display,
        ordinal = tostring(bookmark_entry.group) .. ' ' .. line_content .. ' ' .. file_path,
        path = bookmark_entry.path,
        bookmark_type = bookmark_desc,
        file_icon = file_icon,
        file_color = file_color,
    }
end

---Get file metadata
---@param filepath string
---@return table
local function get_file_metadata(filepath)
    local stat = vim.loop.fs_stat(filepath)
    if not stat then
        return {}
    end

    local size = stat.size
    local mtime = stat.mtime.sec
    local formatted_time = os.date('%Y-%m-%d %H:%M', mtime)

    -- Format file size
    local function format_size(bytes)
        if bytes < 1024 then
            return bytes .. ' B'
        elseif bytes < 1024 * 1024 then
            return string.format('%.1f KB', bytes / 1024)
        elseif bytes < 1024 * 1024 * 1024 then
            return string.format('%.1f MB', bytes / (1024 * 1024))
        else
            return string.format('%.1f GB', bytes / (1024 * 1024 * 1024))
        end
    end

    return {
        size = format_size(size),
        modified = formatted_time,
        lines = vim.fn.line('$') > 0 and vim.fn.line('$') or #vim.fn.readfile(filepath),
    }
end

---Generate enhanced preview content for marks/bookmarks
---@param entry table
---@return string
local function generate_preview(entry)
    if not entry.path or entry.path == '' then
        return ' File Not Found\nThis mark/bookmark does not have an associated file.'
    end

    local file_exists = vim.fn.filereadable(entry.path) == 1

    if not file_exists then
        return string.format(' File Not Found\nPath: %s', entry.path)
    end

    local separator_width = 120
    local lines = {}
    local metadata = get_file_metadata(entry.path)

    -- Read file content
    local file_lines = vim.fn.readfile(entry.path)
    local total_lines = #file_lines
    local target_line = entry.lnum or 1

    -- Ensure target line is valid
    if target_line > total_lines then
        target_line = total_lines
    end

    -- Enhanced context calculation
    local context_before = 8
    local context_after = 8
    local start_line = math.max(1, target_line - context_before)
    local end_line = math.min(total_lines, target_line + context_after)

    -- File header with metadata
    local file_icon, _ = get_filetype_icon(entry.path)
    local rel_path = vim.fn.fnamemodify(entry.path, ':.')

    table.insert(lines, string.format('%s %s', file_icon, rel_path))
    table.insert(lines, string.rep('─', separator_width))

    -- Mark/Bookmark information
    if entry.mark then
        local mark_icon, mark_desc = get_mark_type_info(entry.mark)
        table.insert(lines, string.format('%sMark: %s (%s)', mark_icon, entry.mark, mark_desc))
    elseif entry.group then
        local bookmark_icon, bookmark_desc = get_bookmark_info(entry.group)
        table.insert(lines, string.format('%sBookmark: Group %d (%s)', bookmark_icon, entry.group, bookmark_desc))
    end

    table.insert(lines, string.format('Location: Line %d, Column %d', target_line, entry.col or 1))

    table.insert(lines, '')
    table.insert(lines, string.format('Content (Lines %d-%d of %d):', start_line, end_line, total_lines))

    table.insert(lines, string.rep('─', separator_width))
    table.insert(lines, '')

    -- Add line numbers and content with enhanced formatting
    local max_line_width = string.len(tostring(end_line))

    for i = start_line, end_line do
        local line_content = file_lines[i] or ''
        local is_target = (i == target_line)

        local line_num_str = string.format('%' .. max_line_width .. 'd', i)

        -- Mark target line specially
        local prefix = is_target and '' or ' '

        local line_display = string.format('%s%s│ %s', prefix, line_num_str, line_content)

        table.insert(lines, line_display)

        if is_target and i < end_line then
            table.insert(lines, string.rep(' ', max_line_width + 6) .. '│')
        end
    end

    -- Add navigation hint
    table.insert(lines, '')
    table.insert(lines, string.rep('─', separator_width))
    table.insert(
        lines,
        string.format(
            'Size: %s | Lines: %d | Modified: %s',
            metadata.size or 'Unknown',
            metadata.lines or total_lines,
            metadata.modified or 'Unknown'
        )
    )
    return table.concat(lines, '\n')
end

---Handle selection for marks/bookmarks
---@param prompt_bufnr number|nil
---@param selection table
local function handle_selection(prompt_bufnr, selection)
    if not selection or not selection.value then
        return
    end

    local entry = selection.value
    if entry.path and entry.path ~= '' then
        vim.cmd('edit ' .. vim.fn.fnameescape(entry.path))
    end

    if entry.lnum then
        vim.api.nvim_win_set_cursor(0, { entry.lnum, (entry.col or 1) - 1 })
        vim.cmd('normal! zz') -- Center the line
    end
end

function M.marks_list_buf()
    local results = M.mark_state:get_buf_list()
    if not results or #results == 0 then
        vim.notify('No marks found in current buffer', vim.log.levels.INFO)
        return
    end

    vim.schedule(function()
        pickme.custom_picker({
            items = results,
            title = 'Buffer Marks',
            entry_maker = marks_entry_maker,
            preview_generator = generate_preview,
            selection_handler = handle_selection,
        })
    end)
end

function M.marks_list_all()
    local results = M.mark_state:get_all_list()
    if not results or #results == 0 then
        vim.notify('No marks found', vim.log.levels.INFO)
        return
    end

    vim.schedule(function()
        pickme.custom_picker({
            items = results,
            title = 'All Marks',
            entry_maker = marks_entry_maker,
            preview_generator = generate_preview,
            selection_handler = handle_selection,
        })
    end)
end

function M.bookmarks_list_all()
    local results = M.bookmark_state:get_list({})
    if not results or #results == 0 then
        vim.notify('No bookmarks found', vim.log.levels.INFO)
        return
    end

    vim.schedule(function()
        pickme.custom_picker({
            items = results,
            title = 'All Bookmarks',
            entry_maker = bookmarks_entry_maker,
            preview_generator = generate_preview,
            selection_handler = handle_selection,
        })
    end)
end

function M.bookmarks_list_group(group_nr)
    local results = M.bookmark_state:get_list({ group = group_nr })
    if not results or #results == 0 then
        vim.notify('No bookmarks found in group ' .. group_nr, vim.log.levels.INFO)
        return
    end

    vim.schedule(function()
        pickme.custom_picker({
            items = results,
            title = 'Bookmark Group ' .. group_nr,
            entry_maker = bookmarks_entry_maker,
            preview_generator = generate_preview,
            selection_handler = handle_selection,
        })
    end)
end

M.mappings = {
    set = 'm',
    set_next = 'm,',
    toggle = 'm;',
    toggle_mark = 'M',
    next = 'm]',
    prev = 'm[',
    preview = 'm:',
    next_bookmark = 'm}',
    prev_bookmark = 'm{',
    delete = 'dm',
    delete_line = 'dm-',
    delete_bookmark = 'dm=',
    delete_buf = 'dm<space>',
}

for i = 0, 9 do
    M.mappings['set_bookmark' .. i] = 'm' .. tostring(i)
    M.mappings['delete_bookmark' .. i] = 'dm' .. tostring(i)
end

local function user_mappings(config)
    for cmd, key in pairs(config.mappings) do
        if key ~= false then
            M.mappings[cmd] = key
        else
            M.mappings[cmd] = nil
        end
    end
end

local function apply_mappings()
    for cmd, key in pairs(M.mappings) do
        vim.api.nvim_set_keymap('n', key, '', { callback = M[cmd], desc = 'markit: ' .. cmd:gsub('_', ' ') })
    end
end

local function setup_highlights()
    vim.api.nvim_set_hl(0, 'MarkSignHL', { link = 'Identifier', default = true })
    vim.api.nvim_set_hl(0, 'MarkSignLineHL', { link = 'NONE', default = true })
    vim.api.nvim_set_hl(0, 'MarkSignNumHL', { link = 'CursorLineNr', default = true })
    vim.api.nvim_set_hl(0, 'MarkVirtTextHL', { link = 'Comment', default = true })
end

-- Setup commands
local function setup_commands()
    -- Marks commands
    vim.api.nvim_create_user_command('MarksToggleSigns', function(opts)
        require('markit').toggle_signs(opts.args)
    end, { nargs = '?' })

    vim.api.nvim_create_user_command('MarksListBuf', function()
        require('markit').marks_list_buf()
    end, {})

    vim.api.nvim_create_user_command('MarksListGlobal', function()
        require('markit').marks_list_all()
    end, {})

    vim.api.nvim_create_user_command('MarksListAll', function()
        require('markit').marks_list_all()
    end, {})

    -- Marks quickfix commands
    vim.api.nvim_create_user_command('MarksQFListBuf', function()
        require('markit').mark_state:buffer_to_list('quickfixlist')
        vim.cmd('copen')
    end, {})

    vim.api.nvim_create_user_command('MarksQFListGlobal', function()
        require('markit').mark_state:global_to_list('quickfixlist')
        vim.cmd('copen')
    end, {})

    vim.api.nvim_create_user_command('MarksQFListAll', function()
        require('markit').mark_state:all_to_list('quickfixlist')
        vim.cmd('copen')
    end, {})

    -- Bookmarks commands
    vim.api.nvim_create_user_command('BookmarksList', function(opts)
        local group_nr = tonumber(opts.args)
        if group_nr then
            require('markit').bookmarks_list_group(group_nr)
        else
            require('markit').bookmarks_list_all()
        end
    end, { nargs = '?' })

    vim.api.nvim_create_user_command('BookmarksListAll', function()
        require('markit').bookmarks_list_all()
    end, {})

    -- Bookmarks quickfix commands
    vim.api.nvim_create_user_command('BookmarksQFList', function(opts)
        require('markit').bookmark_state:to_list('quickfixlist', tonumber(opts.args))
        vim.cmd('copen')
    end, { nargs = 1 })

    vim.api.nvim_create_user_command('BookmarksQFListAll', function()
        require('markit').bookmark_state:all_to_list('quickfixlist')
        vim.cmd('copen')
    end, {})
end

local function setup_mappings(config)
    if not config.default_mappings then
        M.mappings = {}
    end
    if config.mappings then
        user_mappings(config)
    end
    apply_mappings()
end

local function setup_autocommands()
    vim.cmd([[augroup Marks_autocmds
    autocmd!
    autocmd BufEnter * lua require'markit'.refresh(true)
    autocmd CursorHold * lua require'markit'.refresh()
    autocmd BufDelete * lua require'markit'._on_delete()
    autocmd VimLeavePre * lua require'markit'.bookmark_state:save()
    autocmd DirChanged * lua require'markit'.bookmark_state:load()
  augroup end]])
end

function M.setup(config)
    config = config or {}

    M.mark_state = mark.new()
    M.mark_state.builtin_marks = config.builtin_marks or {}

    M.bookmark_state = bookmark.new()

    local bookmark_config
    for i = 0, 9 do
        bookmark_config = config['bookmark_' .. i]
        if bookmark_config then
            if bookmark_config.sign == false then
                M.bookmark_state.signs[i] = nil
            else
                M.bookmark_state.signs[i] = bookmark_config.sign or M.bookmark_state.signs[i]
            end
            M.bookmark_state.virt_text[i] = bookmark_config.virt_text or M.bookmark_state.virt_text[i]
            M.bookmark_state.prompt_annotate[i] = bookmark_config.annotate
        end
    end

    local excluded_fts = {}
    for _, ft in ipairs(config.excluded_filetypes or {}) do
        excluded_fts[ft] = true
    end

    M.excluded_fts = excluded_fts

    local excluded_bts = {}
    for _, bt in ipairs(config.excluded_buftypes or {}) do
        excluded_bts[bt] = true
    end

    M.excluded_bts = excluded_bts

    M.bookmark_state.opt.signs = true
    M.bookmark_state.opt.buf_signs = {}

    config.default_mappings = utils.option_nil(config.default_mappings, true)
    setup_mappings(config)
    setup_highlights()
    setup_commands()
    setup_autocommands()

    M.mark_state.opt.signs = utils.option_nil(config.signs, true)
    M.mark_state.opt.buf_signs = {}
    M.mark_state.opt.force_write_shada = utils.option_nil(config.force_write_shada, false)
    M.mark_state.opt.cyclic = utils.option_nil(config.cyclic, true)

    M.mark_state.opt.priority = { 10, 10, 10 }
    local mark_priority = M.mark_state.opt.priority
    if type(config.sign_priority) == 'table' then
        mark_priority[1] = config.sign_priority.lower or mark_priority[1]
        mark_priority[2] = config.sign_priority.upper or mark_priority[2]
        mark_priority[3] = config.sign_priority.builtin or mark_priority[3]
        M.bookmark_state.priority = config.sign_priority.bookmark or 10
    elseif type(config.sign_priority) == 'number' then
        mark_priority[1] = config.sign_priority
        mark_priority[2] = config.sign_priority
        mark_priority[3] = config.sign_priority
        M.bookmark_state.priority = config.sign_priority
    end

    M.bookmark_state:load()
end

return M
