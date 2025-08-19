local M = {
    sign_cache = {},
    path_cache = {},
    buffer_valid_cache = {},
    filetype_cache = {},
}

local builtin_marks = {
    ['.'] = true,
    ['^'] = true,
    ['`'] = true,
    ["'"] = true,
    ['"'] = true,
    ['<'] = true,
    ['>'] = true,
    ['['] = true,
    [']'] = true,
}
for i = 0, 9 do
    builtin_marks[tostring(i)] = true
end

function M.add_sign(bufnr, text, line, id, group, priority)
    priority = priority or 10
    local sign_name = 'Marks_' .. text
    if not M.sign_cache[sign_name] then
        M.sign_cache[sign_name] = true
        vim.fn.sign_define(sign_name, {
            text = text,
            texthl = 'MarkSignHL',
            numhl = 'MarkSignNumHL',
            linehl = 'MarkSignLineHL',
        })
    end
    vim.fn.sign_place(id, group, sign_name, bufnr, { lnum = line, priority = priority })
end

function M.remove_sign(bufnr, id, group)
    group = group or 'MarkSigns'
    vim.fn.sign_unplace(group, { buffer = bufnr, id = id })
end

function M.remove_buf_signs(bufnr, group)
    group = group or 'MarkSigns'
    vim.fn.sign_unplace(group, { buffer = bufnr })
end

function M.search(marks, start_data, init_values, cmp, cyclic)
    local min_next = init_values
    local min_next_set = false
    local min = init_values

    for mark, data in pairs(marks) do
        if cmp(data, start_data, mark) and not cmp(data, min_next, mark) then
            min_next = data
            min_next_set = true
        end
        if cyclic and not cmp(data, min, mark) then
            min = data
        end
    end
    if not cyclic then
        return min_next_set and min_next or nil
    end
    return min_next_set and min_next or min
end

function M.is_valid_mark(char)
    return M.is_letter(char) or builtin_marks[char]
end

function M.is_special(char)
    return builtin_marks[char] ~= nil
end

function M.is_letter(char)
    return M.is_upper(char) or M.is_lower(char)
end

function M.is_upper(char)
    return (65 <= char:byte() and char:byte() <= 90)
end

function M.is_lower(char)
    return (97 <= char:byte() and char:byte() <= 122)
end

function M.option_nil(option, default)
    if option == nil then
        return default
    else
        return option
    end
end

function M.choose_list(list_type)
    local list_fn
    if list_type == 'loclist' then
        list_fn = function(items, flags)
            vim.fn.setloclist(0, items, flags)
        end
    elseif list_type == 'quickfixlist' then
        list_fn = vim.fn.setqflist
    end
    return list_fn
end

function M.clear_caches()
    M.buffer_valid_cache = {}
    M.path_cache = {}
    M.filetype_cache = {}
end

function M.is_valid_buffer(bufnr)
    if not bufnr then
        return false
    end

    local cache_key = tonumber(bufnr)
    if M.buffer_valid_cache[cache_key] ~= nil then
        return M.buffer_valid_cache[cache_key]
    end

    local success, valid = pcall(vim.api.nvim_buf_is_valid, bufnr)
    local result = success and valid
    M.buffer_valid_cache[cache_key] = result

    return result
end

function M.invalidate_buffer(bufnr)
    if bufnr then
        M.buffer_valid_cache[tonumber(bufnr)] = nil
        M.path_cache[tonumber(bufnr)] = nil
    end
end

function M.safe_get_line(bufnr, line_nr)
    if not M.is_valid_buffer(bufnr) then
        return ''
    end

    local success, result = pcall(vim.api.nvim_buf_get_lines, bufnr, line_nr, line_nr + 1, true)
    if success and result and result[1] then
        return result[1]
    end
    return ''
end

function M.safe_get_buf_name(bufnr)
    if not M.is_valid_buffer(bufnr) then
        return ''
    end

    local cache_key = tonumber(bufnr)
    if M.path_cache[cache_key] then
        return M.path_cache[cache_key]
    end

    local success, name = pcall(vim.api.nvim_buf_get_name, bufnr)
    if success then
        M.path_cache[cache_key] = name
        return name
    end
    return ''
end

function M.validate_column(bufnr, line_nr, col)
    local line = M.safe_get_line(bufnr, line_nr)
    if line == '' then
        return 0
    end
    return math.min(col or 0, string.len(line))
end

function M.get_filetype(filename)
    if not filename or filename == '' then
        return 'text'
    end

    local cache_key = filename
    if M.filetype_cache[cache_key] then
        return M.filetype_cache[cache_key]
    end

    local ft = vim.filetype.match({ filename = filename }) or 'text'
    M.filetype_cache[cache_key] = ft

    return ft
end

function M.safe_set_extmark(bufnr, ns_id, line, col, opts)
    if not M.is_valid_buffer(bufnr) then
        return -1
    end

    local success, max_lines = pcall(vim.api.nvim_buf_line_count, bufnr)
    local id
    if not success or line < 0 or line >= max_lines then
        return -1
    end

    local valid_col = M.validate_column(bufnr, line, col)

    success, id = pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, line, valid_col, opts or {})
    if success then
        return id
    end
    return -1
end

function M.setup_cache_handlers()
    local augroup = vim.api.nvim_create_augroup('MarkitCacheManagement', { clear = true })

    vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
        group = augroup,
        callback = function(ev)
            M.invalidate_buffer(ev.buf)
        end,
    })

    vim.api.nvim_create_autocmd('VimLeavePre', {
        group = augroup,
        callback = function()
            M.clear_caches()
        end,
    })
end

function M.safe_create_buffer_state(buffer_state_table, bufnr)
    local utils = require('markit.utils')
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    if not utils.is_valid_buffer(bufnr) then
        return nil
    end

    if not buffer_state_table[bufnr] then
        buffer_state_table[bufnr] = {
            placed_marks = {},
            marks_by_line = {},
            lowest_available_mark = 'a',
        }
    end

    return buffer_state_table[bufnr]
end

function M.safe_get_line_with_fallback(bufnr, line, fallback)
    fallback = fallback or ''

    if not M.is_valid_buffer(bufnr) then
        return fallback
    end

    local success, result = pcall(vim.api.nvim_buf_get_lines, bufnr, line, line + 1, true)
    if success and result and result[1] then
        return result[1]
    end

    return fallback
end

function M.safe_get_current_cursor()
    local success, pos = pcall(vim.api.nvim_win_get_cursor, 0)
    if not success then
        return { 1, 0 }
    end
    return pos
end

return M
