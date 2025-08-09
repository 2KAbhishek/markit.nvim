local pickme = require('pickme')

local M = {}

---Get file type icon based on file extension
---@param filepath string
---@return string icon, string? color
local function get_filetype_icon(filepath)
    if not filepath or filepath == '' then
        return ' ', nil
    end

    local ext = vim.fn.fnamemodify(filepath, ':e'):lower()
    local filename = vim.fn.fnamemodify(filepath, ':t'):lower()

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
    local config = require('markit.config').config
    local colors = { 'Red', 'Orange', 'Yellow', 'Green', 'Blue', 'Indigo', 'Violet', 'Pink', 'Cyan', 'Gray' }
    local color = colors[group_nr + 1] or 'Default'

    local bookmark_config = config.bookmarks[group_nr + 1]
    local icon = ' '
    if bookmark_config then
        icon = bookmark_config.sign
    end

    return icon, color
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

    local line_content = mark_entry.line or ''
    if #line_content > 50 then
        line_content = line_content:sub(1, 47) .. '...'
    end

    local display = string.format(
        '%s %s %s %s:%d  %s',
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

    local line_content = bookmark_entry.line or ''
    if #line_content > 50 then
        line_content = line_content:sub(1, 47) .. '...'
    end

    local display = string.format(
        '%s %d %s %s:%d  %s',
        bookmark_icon,
        bookmark_entry.group or 0,
        file_icon,
        file_path,
        bookmark_entry.lnum or 0,
        line_content
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
    local context_before = 10
    local context_after = 20

    local lines = {}
    local metadata = get_file_metadata(entry.path)

    local file_lines = vim.fn.readfile(entry.path)
    local total_lines = #file_lines
    local target_line = entry.lnum or 1

    if target_line > total_lines then
        target_line = total_lines
    end

    local start_line = math.max(1, target_line - context_before)
    local end_line = math.min(total_lines, target_line + context_after)

    local file_icon, _ = get_filetype_icon(entry.path)
    local rel_path = vim.fn.fnamemodify(entry.path, ':.')
    local filetype = vim.filetype.match({ filename = entry.path }) or 'text'

    table.insert(lines, string.format('# %s %s', file_icon, rel_path))
    table.insert(lines, string.rep('─', separator_width))

    table.insert(
        lines,
        string.format('Size: %s | Modified: %s', metadata.size or 'Unknown', metadata.modified or 'Unknown')
    )
    if entry.mark then
        local mark_icon, mark_desc = get_mark_type_info(entry.mark)
        table.insert(
            lines,
            string.format(
                '%sMark: Ln %d, Col %d %s (%s)',
                mark_icon,
                target_line,
                entry.col or 1,
                entry.mark,
                mark_desc
            )
        )
    elseif entry.group then
        local bookmark_icon, bookmark_desc = get_bookmark_info(entry.group)
        table.insert(
            lines,
            string.format(
                '%sBookmark: Ln %d, Col %d, Group %d (%s)',
                bookmark_icon,
                target_line,
                entry.col or 1,
                entry.group,
                bookmark_desc
            )
        )
    end

    table.insert(lines, '')

    table.insert(lines, string.format('Content (Lines %d-%d of %d):', start_line, end_line, total_lines))
    table.insert(lines, string.rep('─', separator_width))
    table.insert(lines, '```' .. filetype)
    local max_line_width = string.len(tostring(end_line))
    for i = start_line, end_line do
        local line_content = file_lines[i] or ''
        local is_target = (i == target_line)
        local line_num_str = string.format('%' .. max_line_width .. 'd', i)
        local prefix = is_target and ' ' or ' │'
        local line_display = string.format('%s%s %s', prefix, line_num_str, line_content)
        table.insert(lines, line_display)
    end
    table.insert(lines, '```')
    table.insert(lines, string.rep('─', separator_width))

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
        vim.cmd('normal! zz')
    end
end

function M.marks_list_buf(mark_state)
    local results = mark_state:get_buf_list()
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
            preview_ft = 'markdown',
            selection_handler = handle_selection,
        })
    end)
end

function M.marks_list_all(mark_state)
    local results = mark_state:get_all_list()
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
            preview_ft = 'markdown',
            selection_handler = handle_selection,
        })
    end)
end

function M.bookmarks_list_all(bookmark_state)
    local results = bookmark_state:get_list({})
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
            preview_ft = 'markdown',
            selection_handler = handle_selection,
        })
    end)
end

function M.bookmarks_list_group(bookmark_state, group_nr)
    local results = bookmark_state:get_list({ group = group_nr })
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
            preview_ft = 'markdown',
            selection_handler = handle_selection,
        })
    end)
end

return M
