local utils = require('markit.utils')
local a = vim.api
local Path = require('plenary.path')

local Bookmarks = {}

local function group_under_cursor(groups, bufnr, pos)
    bufnr = bufnr or a.nvim_get_current_buf()
    pos = pos or a.nvim_win_get_cursor(0)

    for group_nr, group in pairs(groups) do
        if group.marks[bufnr] then
            for _, mark in pairs(group.marks[bufnr]) do
                if mark.line == pos[1] then
                    return group_nr
                end
            end
        end
    end
    return nil
end

function Bookmarks:init(group_nr)
    local ns = a.nvim_create_namespace('Bookmarks' .. group_nr)
    local sign = self.signs[group_nr]
    local virt_text = self.virt_text[group_nr]

    self.groups[group_nr] = { ns = ns, sign = sign, virt_text = virt_text, marks = {} }
end

-- Add bookmark persistence functions
function Bookmarks:get_bookmarks_dir()
    local dir = Path:new(vim.fn.stdpath('data')):joinpath('markit_bookmarks')
    if not dir:exists() then
        dir:mkdir()
    end
    return dir
end

function Bookmarks:get_root_dir()
    local git_dir = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\n', '')
    if vim.v.shell_error == 0 and git_dir ~= '' then
        return git_dir
    end

    return vim.fn.getcwd()
end

function Bookmarks:get_bookmark_file()
    local root = self:get_root_dir()
    local filename = root:gsub('[^%w_%-]', '_')
    return Path:new(self:get_bookmarks_dir()):joinpath(filename .. '.json')
end

function Bookmarks:save()
    local data = self:serialize()
    local bookmark_file = self:get_bookmark_file()

    local file = io.open(bookmark_file.filename, 'w')
    if file then
        file:write(vim.json.encode(data))
        file:close()
    end
end

function Bookmarks:load()
    local bookmark_file = self:get_bookmark_file()

    if bookmark_file:exists() then
        local file = io.open(bookmark_file.filename, 'r')
        if file then
            local content = file:read('*all')
            file:close()
            local ok, data = pcall(vim.json.decode, content)
            if ok then
                self:deserialize(data)
            end
        end
    end
end

function Bookmarks:serialize()
    local data = {}
    for group_nr, group in pairs(self.groups) do
        local group_key = tostring(group_nr)
        data[group_key] = {
            marks = {},
            sign = self.signs[group_nr],
            virt_text = self.virt_text[group_nr],
        }
        for bufnr, buffer_marks in pairs(group.marks) do
            local filename = vim.api.nvim_buf_get_name(bufnr)
            if filename and filename ~= '' then
                data[group_key].marks[filename] = {}
                for _, mark in pairs(buffer_marks) do
                    table.insert(data[group_key].marks[filename], {
                        line = mark.line,
                        col = mark.col,
                    })
                end
            end
        end
    end
    return data
end

function Bookmarks:deserialize(data)
    if not data then
        return
    end

    for group_key, group_data in pairs(data) do
        local group_nr = tonumber(group_key)
        if not self.groups[group_nr] then
            self:init(group_nr)
        end

        for filename, marks in pairs(group_data.marks) do
            local success, bufnr = pcall(vim.fn.bufadd, filename)
            if success and bufnr and bufnr > 0 then
                pcall(vim.fn.bufload, bufnr)

                if utils.is_valid_buffer(bufnr) then
                    for _, mark in ipairs(marks) do
                        if type(mark.line) == 'number' and mark.line > 0 then
                            local col = type(mark.col) == 'number' and mark.col or 0
                            pcall(function()
                                self:place_mark(group_nr, bufnr, { mark.line, col })
                            end)
                        end
                    end
                end
            end
        end
    end
end

function Bookmarks:place_mark(group_nr, bufnr, pos)
    bufnr = bufnr or a.nvim_get_current_buf()

    if not utils.is_valid_buffer(bufnr) then
        return
    end

    local group = self.groups[group_nr]
    if not group then
        self:init(group_nr)
        group = self.groups[group_nr]
    end

    pos = pos or utils.safe_get_current_cursor()
    local data = { buf = bufnr, line = pos[1], col = pos[2], sign_id = -1 }

    local display_signs = utils.option_nil(self.opt.buf_signs[bufnr], self.opt.signs)
    if display_signs and group.sign then
        local id = group.sign:byte() * 100 + pos[1]
        self:add_sign(bufnr, group.sign, pos[1], id)
        data.sign_id = id
    end

    local opts = {}
    if group.virt_text then
        opts.virt_text = { { group.virt_text, 'MarkVirtTextHL' } }
        opts.virt_text_pos = 'eol'
    end

    if not utils.is_valid_buffer(bufnr) then
        return
    end

    local extmark_id = utils.safe_set_extmark(bufnr, group.ns, pos[1] - 1, pos[2], opts)

    if extmark_id < 0 then
        return
    end

    data.extmark_id = extmark_id

    if not group.marks[bufnr] then
        group.marks[bufnr] = {}
    end

    local mark_key = string.format('%d_%d', pos[1], #group.marks[bufnr] + 1)
    group.marks[bufnr][mark_key] = data

    if self.prompt_annotate[group_nr] then
        self:annotate(group_nr)
    end
end

function Bookmarks:toggle_mark(group_nr, bufnr)
    bufnr = bufnr or a.nvim_get_current_buf()
    local group = self.groups[group_nr]

    if not group then
        self:init(group_nr)
        group = self.groups[group_nr]
    end

    local pos = a.nvim_win_get_cursor(0)

    local found_mark = nil
    if group.marks[bufnr] then
        for key, mark in pairs(group.marks[bufnr]) do
            if mark.line == pos[1] then
                found_mark = key
                break
            end
        end
    end

    if found_mark then
        self:delete_mark(group_nr, bufnr, found_mark)
    else
        self:place_mark(group_nr)
    end
end

function Bookmarks:delete_mark(group_nr, bufnr, mark_key)
    bufnr = bufnr or a.nvim_get_current_buf()
    local group = self.groups[group_nr]

    if not group then
        return
    end

    local mark = group.marks[bufnr] and group.marks[bufnr][mark_key]

    if not mark then
        return
    end

    if mark.sign_id then
        utils.remove_sign(bufnr, mark.sign_id, 'BookmarkSigns')
    end

    a.nvim_buf_del_extmark(bufnr, group.ns, mark.extmark_id)
    group.marks[bufnr][mark_key] = nil
end

function Bookmarks:delete_mark_cursor()
    local bufnr = a.nvim_get_current_buf()

    if not utils.is_valid_buffer(bufnr) then
        return
    end

    local pos = utils.safe_get_current_cursor()

    local group_nr = group_under_cursor(self.groups, bufnr, pos)
    if not group_nr then
        return
    end

    local found_mark = nil
    if self.groups[group_nr].marks[bufnr] then
        for key, mark in pairs(self.groups[group_nr].marks[bufnr]) do
            if mark.line == pos[1] then
                found_mark = key
                break
            end
        end
    end

    if found_mark then
        self:delete_mark(group_nr, bufnr, found_mark)
    end
end

function Bookmarks:delete_all(group_nr)
    local group = self.groups[group_nr]
    if not group then
        return
    end

    for bufnr, buf_marks in pairs(group.marks) do
        for _, mark in pairs(buf_marks) do
            if mark.sign_id then
                utils.remove_sign(bufnr, mark.sign_id, 'BookmarkSigns')
            end

            a.nvim_buf_del_extmark(bufnr, group.ns, mark.extmark_id)
        end
        group.marks[bufnr] = nil
    end
end

local function get_group_nr_or_first(self, bufnr, pos)
    local group_nr = group_under_cursor(self.groups, bufnr, pos)
    if not group_nr then
        for nr, _ in pairs(self.groups) do
            group_nr = nr
            break
        end
    end
    return group_nr
end

local function find_mark(items, bufnr, pos, next_mode)
    if vim.tbl_isempty(items) then
        return nil
    end

    table.sort(items, function(a, b)
        if a.bufnr == b.bufnr then
            if next_mode then
                return a.lnum < b.lnum
            else
                return a.lnum > b.lnum
            end
        end
        if next_mode then
            return a.bufnr < b.bufnr
        else
            return a.bufnr > b.bufnr
        end
    end)

    local found_mark = nil
    for _, mark in ipairs(items) do
        if next_mode then
            if (mark.bufnr > bufnr) or (mark.bufnr == bufnr and mark.lnum > pos[1]) then
                found_mark = mark
                break
            end
        else
            if (mark.bufnr < bufnr) or (mark.bufnr == bufnr and mark.lnum < pos[1]) then
                found_mark = mark
                break
            end
        end
    end

    return found_mark or items[1]
end

function Bookmarks:navigate(group_nr, next_mode)
    local bufnr = a.nvim_get_current_buf()
    local pos = a.nvim_win_get_cursor(0)

    if not group_nr then
        group_nr = get_group_nr_or_first(self, bufnr, pos)
    end

    local items = self:get_list({ group = group_nr })
    local target_mark = find_mark(items, bufnr, pos, next_mode)

    if not target_mark then
        return
    end

    if target_mark.bufnr ~= bufnr then
        vim.cmd('silent b' .. target_mark.bufnr)
        self:load()
    end
    a.nvim_win_set_cursor(0, { target_mark.lnum, target_mark.col - 1 })
end

function Bookmarks:next(group_nr)
    self:navigate(group_nr, true)
end

function Bookmarks:prev(group_nr)
    self:navigate(group_nr, false)
end

function Bookmarks:annotate(group_nr)
    if vim.fn.has('nvim-0.6') ~= 1 then
        error('virtual line annotations requires neovim 0.6 or higher')
    end

    local bufnr = a.nvim_get_current_buf()
    local pos = a.nvim_win_get_cursor(0)

    group_nr = group_nr or group_under_cursor(self.groups, bufnr, pos)

    if not group_nr then
        return
    end

    local bookmark = self.groups[group_nr].marks[bufnr][pos[1]]

    if not bookmark then
        return
    end

    local text = vim.fn.input('annotation: ')

    if text ~= '' then
        a.nvim_buf_set_extmark(bufnr, self.groups[group_nr].ns, bookmark.line - 1, bookmark.col, {
            id = bookmark.extmark_id,
            virt_lines = { { { text, 'MarkVirtTextHL' } } },
            virt_lines_above = true,
        })
    else
        a.nvim_buf_del_extmark(bufnr, self.groups[group_nr].ns, bookmark.extmark_id)

        local opts = {}
        if self.groups[group_nr].virt_text then
            opts.virt_text = { { self.groups[group_nr].virt_text, 'MarkVirtTextHL' } }
            opts.virt_text_pos = 'eol'
        end
        bookmark.extmark_id =
            a.nvim_buf_set_extmark(bufnr, self.groups[group_nr].ns, bookmark.line - 1, bookmark.col, opts)
    end
end

function Bookmarks:refresh()
    local bufnr = a.nvim_get_current_buf()

    local buf_marks
    local display_signs
    utils.remove_buf_signs(bufnr, 'BookmarkSigns')
    for _, group in pairs(self.groups) do
        buf_marks = group.marks[bufnr]
        if buf_marks then
            for _, mark in pairs(vim.tbl_values(buf_marks)) do
                local line = a.nvim_buf_get_extmark_by_id(bufnr, group.ns, mark.extmark_id, {})[1]

                if line + 1 ~= mark.line then
                    buf_marks[line + 1] = mark
                    buf_marks[mark.line] = nil
                    buf_marks[line + 1].line = line + 1
                end
                display_signs = utils.option_nil(self.opt.buf_signs[bufnr], self.opt.signs)
                if display_signs and group.sign then
                    self:add_sign(bufnr, group.sign, line + 1, mark.sign_id)
                end
            end
        end
    end
end

---Helper function to get all bookmark files
local function get_bookmark_files(self, project_only)
    local bookmarks_dir = self:get_bookmarks_dir()
    if project_only then
        local bookmark_file = self:get_bookmark_file()
        return { bookmark_file.filename }
    end
    return vim.fn.glob(bookmarks_dir.filename .. '/*.json', true, true)
end

local function read_bookmark_file(file)
    local f = io.open(file, 'r')
    if not f then
        return nil
    end

    local content = f:read('*all')
    f:close()

    local ok, data = pcall(vim.json.decode, content)
    return ok and data or nil
end

---Helper function to process marks from a group
local function process_group_marks(group_data, group_nr, buffer_filter, project_filter)
    local items = {}
    for filepath, marks in pairs(group_data.marks) do
        if vim.fn.filereadable(filepath) == 1 then
            local bufnr = vim.fn.bufadd(filepath)
            vim.fn.bufload(bufnr)

            if
                (not buffer_filter or bufnr == buffer_filter)
                and (not project_filter or (filepath:sub(1, #project_filter) == project_filter))
            then
                for _, mark in ipairs(marks) do
                    local text = vim.api.nvim_buf_get_lines(bufnr, mark.line - 1, mark.line, false)[1] or ''
                    table.insert(items, {
                        bufnr = bufnr,
                        lnum = mark.line,
                        col = mark.col + 1,
                        group = group_nr,
                        line = vim.trim(text),
                        path = filepath,
                    })
                end
            end
        end
    end
    return items
end

function Bookmarks:get_list(opts)
    opts = opts or {}
    local items = {}

    local files = get_bookmark_files(self, opts.project_only)
    local buffer_filter = opts.buffer
    local project_filter = opts.project and require('markit.utils').get_git_root() or nil

    for _, file in ipairs(files) do
        local data = read_bookmark_file(file)
        if data then
            if opts.group then
                if data[tostring(opts.group)] then
                    local group_data = data[tostring(opts.group)]
                    items = vim.list_extend(
                        items,
                        process_group_marks(group_data, opts.group, buffer_filter, project_filter)
                    )
                end
            else
                for group_key, group_data in pairs(data) do
                    local group_nr = tonumber(group_key)
                    items =
                        vim.list_extend(items, process_group_marks(group_data, group_nr, buffer_filter, project_filter))
                end
            end
        end
    end

    return items
end

function Bookmarks:get_buffer_list(bufnr)
    self:refresh()
    return self:get_list({ buffer = bufnr })
end

function Bookmarks:get_project_list(cwd)
    self:refresh()
    return self:get_list({ project = true })
end

function Bookmarks:to_list(list_type, group_nr)
    if not group_nr or not self.groups[group_nr] then
        return
    end

    list_type = list_type or 'loclist'
    local list_fn = utils.choose_list(list_type)

    local items = {}
    for bufnr, buffer_marks in pairs(self.groups[group_nr].marks) do
        if utils.is_valid_buffer(bufnr) then
            for mark_key, mark in pairs(buffer_marks) do
                local text = utils.safe_get_line(bufnr, mark.line - 1)
                table.insert(items, {
                    bufnr = bufnr,
                    lnum = mark.line,
                    col = mark.col + 1,
                    text = text,
                })
            end
        else
            self.groups[group_nr].marks[bufnr] = nil
        end
    end

    list_fn(items, 'r')
end

function Bookmarks:buffer_to_list(list_type, bufnr)
    list_type = list_type or 'loclist'
    bufnr = bufnr or a.nvim_get_current_buf()

    local list_fn = utils.choose_list(list_type)
    local items = {}

    for group_nr, group in pairs(self.groups) do
        if group.marks[bufnr] then
            for mark_key, mark in pairs(group.marks[bufnr]) do
                local text = utils.safe_get_line(bufnr, mark.line - 1)
                table.insert(items, {
                    bufnr = bufnr,
                    lnum = mark.line,
                    col = mark.col + 1,
                    text = 'bookmark ' .. group_nr .. ': ' .. text,
                })
            end
        end
    end

    list_fn(items, 'r')
end

function Bookmarks:project_to_list(list_type)
    list_type = list_type or 'loclist'
    local list_fn = utils.choose_list(list_type)
    local items = {}
    local git_root = utils.get_git_root()

    if not git_root then
        vim.notify('Not in a git repository', vim.log.levels.WARN)
        return
    end

    for group_nr, group in pairs(self.groups) do
        for bufnr, buffer_marks in pairs(group.marks) do
            if utils.is_valid_buffer(bufnr) then
                local filepath = vim.api.nvim_buf_get_name(bufnr)
                if filepath:sub(1, #git_root) == git_root then
                    for mark_key, mark in pairs(buffer_marks) do
                        local text = utils.safe_get_line(bufnr, mark.line - 1)
                        table.insert(items, {
                            bufnr = bufnr,
                            lnum = mark.line,
                            col = mark.col + 1,
                            text = 'bookmark ' .. group_nr .. ': ' .. text,
                        })
                    end
                end
            else
                group.marks[bufnr] = nil
            end
        end
    end

    list_fn(items, 'r')
end

function Bookmarks:all_to_list(list_type)
    list_type = list_type or 'loclist'
    local list_fn = utils.choose_list(list_type)

    local items = {}
    local invalid_buffers = {}

    for group_nr, group in pairs(self.groups) do
        for bufnr, buffer_marks in pairs(group.marks) do
            if utils.is_valid_buffer(bufnr) then
                for mark_key, mark in pairs(buffer_marks) do
                    local text = utils.safe_get_line(bufnr, mark.line - 1)
                    table.insert(items, {
                        bufnr = bufnr,
                        lnum = mark.line,
                        col = mark.col + 1,
                        text = 'bookmark group ' .. group_nr .. ': ' .. text,
                    })
                end
            else
                if not invalid_buffers[group_nr] then
                    invalid_buffers[group_nr] = {}
                end
                table.insert(invalid_buffers[group_nr], bufnr)
            end
        end
    end

    for group_nr, bufnrs in pairs(invalid_buffers) do
        for _, bufnr in ipairs(bufnrs) do
            self.groups[group_nr].marks[bufnr] = nil
        end
    end

    list_fn(items, 'r')
end

function Bookmarks:add_sign(bufnr, text, line, id)
    utils.add_sign(bufnr, text, line, id, 'BookmarkSigns', self.priority)
end

function Bookmarks.new()
    return setmetatable({
        signs = { '!', '@', '#', '$', '%', '^', '&', '*', '(', [0] = ')' },
        virt_text = {},
        groups = {},
        prompt_annotate = {},
        opt = {},
    }, { __index = Bookmarks })
end

return Bookmarks
