local a = vim.api
local utils = require('markit.utils')

local Mark = {}

function Mark:register_mark(mark, line, col, bufnr)
    col = col or 1
    bufnr = bufnr or a.nvim_get_current_buf()
    local buffer = self.buffers[bufnr]

    if not buffer then
        return
    end

    if buffer.placed_marks[mark] then
        self:delete_mark(mark, false)
    end

    if buffer.marks_by_line[line] then
        table.insert(buffer.marks_by_line[line], mark)
    else
        buffer.marks_by_line[line] = { mark }
    end
    buffer.placed_marks[mark] = { line = line, col = col, id = -1 }

    local display_signs = utils.option_nil(self.opt.buf_signs[bufnr], self.opt.signs)
    if display_signs then
        local id = mark:byte() * 100
        buffer.placed_marks[mark].id = id
        self:add_sign(bufnr, mark, line, id)
    end

    if not utils.is_lower(mark) or mark:byte() > buffer.lowest_available_mark:byte() then
        return
    end

    while self.buffers[bufnr].placed_marks[mark] do
        mark = string.char(mark:byte() + 1)
    end
    self.buffers[bufnr].lowest_available_mark = mark
end

function Mark:place_mark_cursor(mark)
    local bufnr = a.nvim_get_current_buf()
    local pos = utils.safe_get_current_cursor()
    self:register_mark(mark, pos[1], pos[2], bufnr)
end

function Mark:place_next_mark(line, col)
    local bufnr = a.nvim_get_current_buf()
    local buffer_state = utils.safe_create_buffer_state(self.buffers, bufnr)

    if not buffer_state then
        return
    end

    local mark = buffer_state.lowest_available_mark
    self:register_mark(mark, line, col, bufnr)

    vim.cmd('normal! m' .. mark)
end

function Mark:place_next_mark_cursor()
    local pos = utils.safe_get_current_cursor()
    self:place_next_mark(pos[1], pos[2])
end

function Mark:delete_mark(mark, clear)
    clear = utils.option_nil(clear, true)
    local bufnr = a.nvim_get_current_buf()

    if not utils.is_valid_buffer(bufnr) then
        return
    end

    local buffer = self.buffers[bufnr]
    if not buffer or not buffer.placed_marks[mark] then
        return
    end

    if buffer.placed_marks[mark].id ~= -1 then
        utils.remove_sign(bufnr, buffer.placed_marks[mark].id)
    end

    local line = buffer.placed_marks[mark].line
    if buffer.marks_by_line[line] then
        for key, tmp_mark in pairs(buffer.marks_by_line[line]) do
            if tmp_mark == mark then
                buffer.marks_by_line[line][key] = nil
                break
            end
        end

        if vim.tbl_isempty(buffer.marks_by_line[line]) then
            buffer.marks_by_line[line] = nil
        end
    end

    buffer.placed_marks[mark] = nil

    if clear then
        vim.cmd('delmark ' .. mark)
    end

    if self.opt.force_write_shada then
        vim.cmd('wshada!')
    end

    if not utils.is_lower(mark) then
        return
    end

    if mark:byte() < buffer.lowest_available_mark:byte() then
        buffer.lowest_available_mark = mark
    end
end

function Mark:delete_line_marks()
    local bufnr = a.nvim_get_current_buf()
    local pos = a.nvim_win_get_cursor(0)

    if not self.buffers[bufnr].marks_by_line[pos[1]] then
        return
    end

    local copy = vim.tbl_values(self.buffers[bufnr].marks_by_line[pos[1]])
    for _, mark in pairs(copy) do
        self:delete_mark(mark)
    end
end

function Mark:toggle_mark_cursor()
    local bufnr = a.nvim_get_current_buf()
    local pos = utils.safe_get_current_cursor()
    local buffer_state = utils.safe_create_buffer_state(self.buffers, bufnr)

    if not buffer_state then
        return
    end

    if buffer_state.marks_by_line[pos[1]] then
        self:delete_line_marks()
    else
        self:place_next_mark(pos[1], pos[2])
    end
end

function Mark:toggle_mark(mark)
    local bufnr = a.nvim_get_current_buf()
    local pos = utils.safe_get_current_cursor()
    local buffer_state = utils.safe_create_buffer_state(self.buffers, bufnr)

    if not buffer_state then
        return
    end

    local is_marked = buffer_state.placed_marks[mark] and buffer_state.placed_marks[mark].line == pos[1]

    if is_marked then
        self:delete_mark(mark)
    else
        self:register_mark(mark, pos[1], pos[2], bufnr)
        vim.cmd('normal! m' .. mark)
    end
end

function Mark:delete_buf_marks(clear)
    clear = utils.option_nil(clear, true)
    local bufnr = a.nvim_get_current_buf()
    self.buffers[bufnr] = {
        placed_marks = {},
        marks_by_line = {},
        lowest_available_mark = 'a',
    }

    utils.remove_buf_signs(bufnr)
    if clear then
        vim.cmd('delmarks!')
    end
end

function Mark:delete_project_marks()
    local git_root = utils.get_git_root()
    if not git_root then
        vim.notify('Not in a git repository', vim.log.levels.WARN)
        return
    end

    for bufnr, buffer_state in pairs(self.buffers) do
        if utils.is_valid_buffer(bufnr) then
            local filepath = utils.safe_get_buf_name(bufnr)

            if filepath:sub(1, #git_root) == git_root then
                self.buffers[bufnr] = {
                    placed_marks = {},
                    marks_by_line = {},
                    lowest_available_mark = 'a',
                }
                utils.remove_buf_signs(bufnr)

                vim.api.nvim_buf_call(bufnr, function()
                    vim.cmd('delmarks!')
                end)
            end
        end
    end
end

function Mark:delete_all_marks()
    for bufnr, buffer_state in pairs(self.buffers) do
        if utils.is_valid_buffer(bufnr) then
            self.buffers[bufnr] = {
                placed_marks = {},
                marks_by_line = {},
                lowest_available_mark = 'a',
            }
            utils.remove_buf_signs(bufnr)

            vim.api.nvim_buf_call(bufnr, function()
                vim.cmd('delmarks!')
            end)
        end
    end

    vim.cmd('delmarks A-Z0-9')
end

function Mark:next_mark()
    local bufnr = a.nvim_get_current_buf()

    if not self.buffers[bufnr] then
        return
    end

    local line = a.nvim_win_get_cursor(0)[1]
    local marks = {}
    for mark, data in pairs(self.buffers[bufnr].placed_marks) do
        if utils.is_letter(mark) then
            marks[mark] = data
        end
    end

    if vim.tbl_isempty(marks) then
        return
    end

    local function comparator(x, y, _)
        return x.line > y.line
    end

    local next = utils.search(marks, { line = line }, { line = math.huge }, comparator, self.opt.cyclic)

    if next then
        a.nvim_win_set_cursor(0, { next.line, next.col })
    end
end

function Mark:prev_mark()
    local bufnr = a.nvim_get_current_buf()

    if not self.buffers[bufnr] then
        return
    end

    local line = a.nvim_win_get_cursor(0)[1]
    local marks = {}
    for mark, data in pairs(self.buffers[bufnr].placed_marks) do
        if utils.is_letter(mark) then
            marks[mark] = data
        end
    end

    if vim.tbl_isempty(marks) then
        return
    end

    local function comparator(x, y, _)
        return x.line < y.line
    end
    local prev = utils.search(marks, { line = line }, { line = -1 }, comparator, self.opt.cyclic)

    if prev then
        a.nvim_win_set_cursor(0, { prev.line, prev.col })
    end
end

function Mark.preview_mark()
    a.nvim_echo({ { 'press letter mark to preview, or press <esc> to quit' } }, true, {})
    local mark = vim.fn.getchar()
    if mark == 27 then
        return
    else
        mark = string.char(mark)
    end

    vim.defer_fn(function()
        a.nvim_echo({ { '' } }, false, {})
    end, 100)

    if not mark then
        return
    end

    local pos = vim.fn.getpos("'" .. mark)
    if pos[2] == 0 then
        return
    end

    local width = a.nvim_win_get_width(0)
    local height = a.nvim_win_get_height(0)

    a.nvim_open_win(pos[1], true, {
        relative = 'win',
        win = 0,
        width = math.floor(width / 2),
        height = math.floor(height / 2),
        col = math.floor(width / 4),
        row = math.floor(height / 8),
        border = 'single',
    })
    vim.cmd('normal! `' .. mark)
    vim.cmd('normal! zz')
end

function Mark:get_buf_list(bufnr)
    bufnr = bufnr or a.nvim_get_current_buf()
    if not self.buffers[bufnr] then
        return
    end

    local items = {}
    for mark, data in pairs(self.buffers[bufnr].placed_marks) do
        local text = a.nvim_buf_get_lines(bufnr, data.line - 1, data.line, true)[1]
        local path = vim.api.nvim_buf_get_name(bufnr)
        table.insert(items, {
            bufnr = bufnr,
            lnum = data.line,
            col = data.col + 1,
            mark = mark,
            line = vim.trim(text),
            path = path,
        })
    end
    return items
end

function Mark:get_all_list()
    local items = {}
    for bufnr, buffer_state in pairs(self.buffers) do
        if utils.is_valid_buffer(bufnr) then
            for mark, data in pairs(buffer_state.placed_marks) do
                local text = utils.safe_get_line(bufnr, data.line - 1)
                local path = utils.safe_get_buf_name(bufnr)

                table.insert(items, {
                    bufnr = bufnr,
                    lnum = data.line,
                    col = data.col + 1,
                    mark = mark,
                    line = vim.trim(text),
                    path = path,
                })
            end
        else
            self.buffers[bufnr] = nil
        end
    end
    return items
end

function Mark:get_global_list()
    local items = {}
    for bufnr, buffer_state in pairs(self.buffers) do
        if utils.is_valid_buffer(bufnr) then
            for mark, data in pairs(buffer_state.placed_marks) do
                if utils.is_upper(mark) then
                    local text = utils.safe_get_line(bufnr, data.line - 1)
                    local path = utils.safe_get_buf_name(bufnr)
                    table.insert(items, {
                        bufnr = bufnr,
                        lnum = data.line,
                        col = data.col + 1,
                        mark = mark,
                        line = vim.trim(text),
                        path = path,
                    })
                end
            end
        else
            self.buffers[bufnr] = nil
        end
    end
    return items
end

function Mark:buffer_to_list(list_type, bufnr)
    list_type = list_type or 'loclist'

    local list_fn = utils.choose_list(list_type)

    bufnr = bufnr or a.nvim_get_current_buf()
    if not self.buffers[bufnr] then
        return
    end

    local items = {}
    for mark, data in pairs(self.buffers[bufnr].placed_marks) do
        local text = a.nvim_buf_get_lines(bufnr, data.line - 1, data.line, true)[1]
        table.insert(items, {
            bufnr = bufnr,
            lnum = data.line,
            col = data.col + 1,
            text = 'mark ' .. mark .. ': ' .. text,
        })
    end

    list_fn(items, 'r')
end

function Mark:all_to_list(list_type)
    list_type = list_type or 'loclist'

    local list_fn = utils.choose_list(list_type)

    local items = {}
    for bufnr, buffer_state in pairs(self.buffers) do
        for mark, data in pairs(buffer_state.placed_marks) do
            local text = a.nvim_buf_get_lines(bufnr, data.line - 1, data.line, true)[1]
            table.insert(items, {
                bufnr = bufnr,
                lnum = data.line,
                col = data.col + 1,
                text = 'mark ' .. mark .. ': ' .. text,
            })
        end
    end

    list_fn(items, 'r')
end

function Mark:global_to_list(list_type)
    list_type = list_type or 'loclist'

    local list_fn = utils.choose_list(list_type)

    local items = {}
    for bufnr, buffer_state in pairs(self.buffers) do
        for mark, data in pairs(buffer_state.placed_marks) do
            if utils.is_upper(mark) then
                local text = a.nvim_buf_get_lines(bufnr, data.line - 1, data.line, true)[1]
                table.insert(items, {
                    bufnr = bufnr,
                    lnum = data.line,
                    col = data.col + 1,
                    text = 'mark ' .. mark .. ': ' .. text,
                })
            end
        end
    end

    list_fn(items, 'r')
end

function Mark:refresh(bufnr, force)
    force = force or false
    bufnr = bufnr or a.nvim_get_current_buf()

    if not utils.is_valid_buffer(bufnr) then
        if self.buffers[bufnr] then
            self.buffers[bufnr] = nil
        end
        return
    end

    if not self.buffers[bufnr] then
        self.buffers[bufnr] = {
            placed_marks = {},
            marks_by_line = {},
            lowest_available_mark = 'a',
        }
    end

    local buffer_state = self.buffers[bufnr]
    local mark, pos, cached_mark

    for mark, _ in pairs(buffer_state.placed_marks) do
        local success, mark_pos = pcall(a.nvim_buf_get_mark, bufnr, mark)
        if not success or mark_pos[1] == 0 then
            self:delete_mark(mark, false)
        end
    end

    local global_marks = vim.fn.getmarklist()
    for _, data in ipairs(global_marks) do
        mark = data.mark:sub(2, 3)
        pos = data.pos
        cached_mark = buffer_state.placed_marks[mark]

        if utils.is_upper(mark) and pos[1] == bufnr and (force or not cached_mark or pos[2] ~= cached_mark.line) then
            self:register_mark(mark, pos[2], pos[3], bufnr)
        end
    end

    local local_marks = vim.fn.getmarklist('%')
    for _, data in ipairs(local_marks) do
        mark = data.mark:sub(2, 3)
        pos = data.pos
        cached_mark = buffer_state.placed_marks[mark]

        if utils.is_lower(mark) and (force or not cached_mark or pos[2] ~= cached_mark.line) then
            self:register_mark(mark, pos[2], pos[3], bufnr)
        end
    end

    if #self.builtin_marks > 0 then
        for _, char in pairs(self.builtin_marks) do
            local success, mark_pos = pcall(vim.fn.getpos, "'" .. char)
            if success then
                pos = mark_pos
                cached_mark = buffer_state.placed_marks[char]

                if
                    (pos[1] == 0 or pos[1] == bufnr)
                    and pos[2] ~= 0
                    and (force or not cached_mark or pos[2] ~= cached_mark.line)
                then
                    self:register_mark(char, pos[2], pos[3], bufnr)
                end
            end
        end
    end
end

function Mark:add_sign(bufnr, text, line, id)
    local priority
    if utils.is_lower(text) then
        priority = self.opt.priority[1]
    elseif utils.is_upper(text) then
        priority = self.opt.priority[2]
    else
        priority = self.opt.priority[3]
    end
    utils.add_sign(bufnr, text, line, id, 'MarkSigns', priority)
end

function Mark.new()
    return setmetatable({ buffers = {}, opt = {} }, { __index = Mark })
end

return Mark
