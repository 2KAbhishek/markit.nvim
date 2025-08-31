local M = {}

---Parse command line arguments, removing empty strings
---@param cmdline string
---@return string[]
local function parse_args(cmdline)
    local args = vim.split(cmdline, ' ')
    return vim.tbl_filter(function(arg)
        return arg ~= ''
    end, args)
end

---Filter items by prefix match
---@param items string[]
---@param prefix string
---@return string[]
local function filter_by_prefix(items, prefix)
    return vim.tbl_filter(function(item)
        return item:sub(1, #prefix) == prefix
    end, items)
end

---Get completion options for different contexts
---@param context string
---@return string[]
local function get_completion_options(context)
    local options = {
        domains = { 'mark', 'bookmark' },
        mark_actions = { 'list', 'toggle', 'set', 'delete', 'next', 'prev', 'goto', 'preview' },
        bookmark_actions = { 'list', 'toggle', 'annotate', 'delete', 'next', 'prev', 'goto', 'signs' },
        mark_list_scopes = { 'buffer', 'project', 'all', 'type', 'quickfix' },
        mark_delete_scopes = { 'line', 'buffer', 'project', 'all' },
        bookmark_list_scopes = { 'buffer', 'project', 'all', 'quickfix' },
        bookmark_delete_scopes = { 'line', 'buffer', 'project', 'all' },
        bookmark_groups = {},
    }

    if context == 'bookmark_list_scopes' or context == 'bookmark_groups' then
        for i = 0, 9 do
            table.insert(options[context], tostring(i))
        end
    end

    return options[context] or {}
end

---Handle mark domain commands
---@param args string[]
local function handle_mark_command(args)
    local action = args[2] or ''

    if action == 'list' then
        if args[3] == 'quickfix' then
            local scope = args[4] or 'all'
            if scope == 'buffer' then
                require('markit').mark_state:buffer_to_list('quickfixlist')
                vim.cmd('copen')
            elseif scope == 'project' then
                require('markit').mark_state:project_to_list('quickfixlist')
                vim.cmd('copen')
            elseif scope == 'all' then
                require('markit').mark_state:all_to_list('quickfixlist')
                vim.cmd('copen')
            else
                require('markit').mark_state:all_to_list('quickfixlist')
                vim.cmd('copen')
            end
        else
            local scope = args[3] or 'all'
            if scope == 'buffer' then
                require('markit').marks_list_buf()
            elseif scope == 'project' then
                require('markit').marks_list_project()
            elseif scope == 'all' then
                require('markit').marks_list_all()
            else
                require('markit').marks_list_all()
            end
        end
    elseif action == 'toggle' then
        local mark_char = args[3]
        if mark_char then
            require('markit').toggle_mark(mark_char)
        else
            require('markit').toggle()
        end
    elseif action == 'set' then
        local mark_char = args[3]
        if mark_char then
            require('markit').set(mark_char)
        else
            require('markit').set_next()
        end
    elseif action == 'delete' then
        local scope = args[3] or 'line'
        local mark_char = args[4]

        if scope == 'line' and mark_char then
            require('markit').delete(mark_char)
        elseif scope == 'line' then
            require('markit').delete_line()
        elseif scope == 'buffer' then
            require('markit').delete_buf()
        elseif scope == 'project' then
            require('markit').delete_project()
        elseif scope == 'all' then
            require('markit').delete_all()
        else
            vim.notify(
                "Unknown mark delete scope: '" .. scope .. "'. Expected one of: line, buffer, project, all",
                vim.log.levels.ERROR
            )
        end
    elseif action == 'next' then
        require('markit').next()
    elseif action == 'prev' then
        require('markit').prev()
    elseif action == 'goto' then
        local mark_char = args[3]
        if mark_char then
            vim.cmd('normal! `' .. mark_char)
        else
            vim.notify('Mark character required for goto. Usage: Markit mark goto <mark_char>', vim.log.levels.ERROR)
        end
    elseif action == 'preview' then
        require('markit').preview()
    else
        vim.notify(
            [[
Markit mark usage:
  mark list [scope]               - List marks (scope: buffer, project, all, type)
  mark list quickfix [scope]      - Send marks to quickfix
  mark toggle [mark_char]         - Toggle mark at cursor
  mark set [mark_char]            - Set mark at cursor
  mark delete [scope] [mark_char] - Delete marks
  mark next                       - Go to next mark
  mark prev                       - Go to previous mark
  mark goto <mark_char>           - Go to specific mark
  mark preview                    - Preview mark at cursor
]],
            vim.log.levels.INFO
        )
    end
end

---Handle bookmark domain commands
---@param args string[]
local function handle_bookmark_command(args)
    local action = args[2] or ''

    if action == 'list' then
        if args[3] == 'quickfix' then
            local scope = args[4]
            if scope and tonumber(scope) then
                require('markit').bookmark_state:to_list('quickfixlist', tonumber(scope))
                vim.cmd('copen')
            elseif scope == 'buffer' then
                require('markit').bookmark_state:buffer_to_list('quickfixlist')
                vim.cmd('copen')
            elseif scope == 'project' then
                require('markit').bookmark_state:project_to_list('quickfixlist')
                vim.cmd('copen')
            else
                require('markit').bookmark_state:all_to_list('quickfixlist')
                vim.cmd('copen')
            end
        else
            local scope = args[3]
            if scope and tonumber(scope) then
                require('markit').bookmarks_list_group(tonumber(scope))
            elseif scope == 'buffer' then
                require('markit').bookmarks_list_buffer()
            elseif scope == 'project' then
                require('markit').bookmarks_list_project()
            else
                require('markit').bookmarks_list_all()
            end
        end
    elseif action == 'toggle' then
        local group_nr = tonumber(args[3] or '0')
        require('markit')['toggle_bookmark' .. group_nr]()
    elseif action == 'annotate' then
        require('markit').annotate()
    elseif action == 'delete' and args[3] and not string.match(args[3], '^[a-z]+$') then
        local group_nr = tonumber(args[3] or '0')
        require('markit')['delete_bookmark' .. group_nr]()
    elseif action == 'next' then
        local group_nr = args[3]
        if group_nr and tonumber(group_nr) then
            require('markit')['next_bookmark' .. tonumber(group_nr)]()
        else
            require('markit').next_bookmark()
        end
    elseif action == 'prev' then
        local group_nr = args[3]
        if group_nr and tonumber(group_nr) then
            require('markit')['prev_bookmark' .. tonumber(group_nr)]()
        else
            require('markit').prev_bookmark()
        end
    elseif action == 'goto' then
        local group_nr = args[3]
        if group_nr and tonumber(group_nr) then
            require('markit')['next_bookmark' .. tonumber(group_nr)](true)
        else
            vim.notify(
                'Group number required for bookmark goto. Usage: Markit bookmark goto <group_number> (0-9)',
                vim.log.levels.ERROR
            )
        end
    elseif action == 'delete' then
        local scope = args[3] or 'line'

        if scope == 'line' then
            require('markit').delete_bookmark()
        elseif scope == 'buffer' then
            require('markit').bookmark_state:buffer_to_list('quickfixlist')
            local group_nr = tonumber(args[4] or '0')
            require('markit')['delete_bookmark' .. group_nr]()
        elseif scope == 'project' then
            local group_nr = tonumber(args[4] or '0')
            require('markit')['delete_bookmark' .. group_nr]()
        elseif scope == 'all' then
            for i = 0, 9 do
                require('markit')['delete_bookmark' .. i]()
            end
        else
            vim.notify(
                "Unknown bookmark delete scope: '" .. scope .. "'. Expected one of: line, buffer, project, all",
                vim.log.levels.ERROR
            )
        end
    elseif action == 'signs' then
        local bufnr = tonumber(args[3])
        require('markit').toggle_signs(bufnr)
    else
        vim.notify(
            [[
Markit bookmark usage:
  bookmark list [scope]           - List bookmarks (scope: buffer, project, all, group)
  bookmark list quickfix [scope]  - Send bookmarks to quickfix
  bookmark toggle [group]         - Toggle bookmark at cursor
  bookmark annotate               - Annotate bookmark at cursor
  bookmark delete [group]          - Delete bookmarks in group
  bookmark next [group]           - Go to next bookmark
  bookmark prev [group]           - Go to previous bookmark
  bookmark goto <group>           - Go to specific bookmark group
  bookmark delete [scope] [group] - Delete bookmarks (scope: line, buffer, project, all)
  bookmark signs [buffer]         - Toggle signs display
]],
            vim.log.levels.INFO
        )
    end
end

---Show help information for Markit command
local function show_help()
    vim.notify(
        [[
Markit Usage:

Mark Commands:
  mark list [scope]               - List marks (scope: buffer, project, all, type)
  mark list quickfix [scope]      - Send marks to quickfix
  mark toggle [mark_char]         - Toggle mark at cursor
  mark set [mark_char]            - Set mark at cursor
  mark delete [scope] [mark_char] - Delete marks
  mark next                       - Go to next mark
  mark prev                       - Go to previous mark
  mark goto <mark_char>           - Go to specific mark
  mark preview                    - Preview mark at cursor

Bookmark Commands:
  bookmark list [scope]           - List bookmarks (scope: buffer, project, all, group)
  bookmark list quickfix [scope]  - Send bookmarks to quickfix
  bookmark toggle [group]         - Toggle bookmark at cursor
  bookmark annotate               - Annotate bookmark at cursor
  bookmark delete [group]          - Delete bookmarks in group
  bookmark next [group]           - Go to next bookmark
  bookmark prev [group]           - Go to previous bookmark
  bookmark goto <group>           - Go to specific bookmark group
  bookmark delete [scope] [group] - Delete bookmarks (scope: line, buffer, project, all)
  bookmark signs [buffer]         - Toggle signs display
]],
        vim.log.levels.INFO
    )
end

---Main command handler for the unified Markit command
---@param opts table
local function markit_command(opts)
    local args = parse_args(opts.args)

    if #args == 0 then
        show_help()
        return
    end

    local domain = args[1] or ''

    local handlers = {
        mark = handle_mark_command,
        bookmark = handle_bookmark_command,
    }

    local handler = handlers[domain]
    if handler then
        handler(args)
    else
        show_help()
    end
end

---Main completion function for Markit command
---@param arg_lead string
---@param cmd_line string
---@param cursor_pos integer
---@return string[]
local function complete_markit(arg_lead, cmd_line, cursor_pos)
    cmd_line = cmd_line:gsub('^%s*Markit%s*', '')
    local args = parse_args(cmd_line)
    local arg_count = #args

    if arg_count == 0 or (arg_count == 1 and arg_lead ~= '') then
        return filter_by_prefix(get_completion_options('domains'), arg_lead)
    end
    local domain = args[1]

    if (arg_count == 1 and arg_lead == '') or (arg_count == 2 and arg_lead ~= '') then
        if domain == 'mark' then
            return filter_by_prefix(get_completion_options('mark_actions'), arg_lead)
        elseif domain == 'bookmark' then
            return filter_by_prefix(get_completion_options('bookmark_actions'), arg_lead)
        end
    end

    local action = args[2]

    if domain == 'mark' then
        if action == 'list' and (arg_count == 2 or (arg_count == 3 and arg_lead ~= '')) then
            return filter_by_prefix(get_completion_options('mark_list_scopes'), arg_lead)
        elseif
            action == 'list'
            and args[3] == 'quickfix'
            and (arg_count == 3 or (arg_count == 4 and arg_lead ~= ''))
        then
            local scopes = { 'buffer', 'project', 'all', 'type' }
            return filter_by_prefix(scopes, arg_lead)
        elseif action == 'delete' and (arg_count == 2 or (arg_count == 3 and arg_lead ~= '')) then
            return filter_by_prefix(get_completion_options('mark_delete_scopes'), arg_lead)
        elseif
            (action == 'toggle' or action == 'set' or action == 'goto')
            and (arg_count == 2 or (arg_count == 3 and arg_lead ~= ''))
        then
            local valid_marks = {}
            for i = string.byte('a'), string.byte('z') do
                table.insert(valid_marks, string.char(i))
            end
            for i = string.byte('A'), string.byte('Z') do
                table.insert(valid_marks, string.char(i))
            end
            for i = 0, 9 do
                table.insert(valid_marks, tostring(i))
            end

            return filter_by_prefix(valid_marks, arg_lead)
        end
    elseif domain == 'bookmark' then
        if action == 'list' and (arg_count == 2 or (arg_count == 3 and arg_lead ~= '')) then
            local options = { 'buffer', 'project', 'all', 'quickfix' }
            for i = 0, 9 do
                table.insert(options, tostring(i))
            end

            return filter_by_prefix(options, arg_lead)
        elseif
            action == 'list'
            and args[3] == 'quickfix'
            and (arg_count == 3 or (arg_count == 4 and arg_lead ~= ''))
        then
            local options = { 'buffer', 'project', 'all' }
            for i = 0, 9 do
                table.insert(options, tostring(i))
            end

            return filter_by_prefix(options, arg_lead)
        elseif action == 'delete' and (arg_count == 2 or (arg_count == 3 and arg_lead ~= '')) then
            return filter_by_prefix(get_completion_options('bookmark_delete_scopes'), arg_lead)
        elseif action == 'delete' and (arg_count == 3 or (arg_count == 4 and arg_lead ~= '')) then
            local options = {}
            for i = 0, 9 do
                table.insert(options, tostring(i))
            end
            return filter_by_prefix(options, arg_lead)
        elseif action == 'signs' and (arg_count == 2 or (arg_count == 3 and arg_lead ~= '')) then
            local options = {}
            local buffers = vim.api.nvim_list_bufs()
            for _, buf in ipairs(buffers) do
                if vim.api.nvim_buf_is_loaded(buf) then
                    table.insert(options, tostring(buf))
                end
            end
            return filter_by_prefix(options, arg_lead)
        elseif
            vim.tbl_contains({ 'toggle', 'next', 'prev', 'goto', 'delete' }, action)
            and (arg_count == 2 or (arg_count == 3 and arg_lead ~= ''))
        then
            local options = {}
            for i = 0, 9 do
                table.insert(options, tostring(i))
            end

            return filter_by_prefix(options, arg_lead)
        end
    end

    if
        domain == 'mark'
        and action == 'delete'
        and args[3] == 'line'
        and (arg_count == 3 or (arg_count == 4 and arg_lead ~= ''))
    then
        local valid_marks = {}
        for i = string.byte('a'), string.byte('z') do
            table.insert(valid_marks, string.char(i))
        end
        for i = string.byte('A'), string.byte('Z') do
            table.insert(valid_marks, string.char(i))
        end

        return filter_by_prefix(valid_marks, arg_lead)
    end

    return {}
end

local function setup_default_keybindings(config)
    local mappings = {
        { '<leader>mm', ':Markit mark list all<cr>', 'All Marks' },
        { '<leader>mM', ':Markit mark list buffer<cr>', 'Buffer Marks' },
        { '<leader>ms', ':Markit mark set<cr>', 'Set Next Available Mark' },
        { '<leader>mS', ':Markit mark set<cr>', 'Set Mark (Interactive)' },
        { '<leader>mt', ':Markit mark toggle<cr>', 'Toggle Mark at Cursor' },
        { '<leader>mT', ':Markit mark toggle<cr>', 'Toggle Mark (Interactive)' },

        { '<leader>mj', ':Markit mark next<cr>', 'Next Mark' },
        { '<leader>mk', ':Markit mark prev<cr>', 'Previous Mark' },
        { '<leader>mP', ':Markit mark preview<cr>', 'Preview Mark' },

        { '<leader>md', ':Markit mark delete line<cr>', 'Delete Marks In Line' },
        { '<leader>mD', ':Markit mark delete buffer<cr>', 'Delete Marks In Buffer' },
        { '<leader>mX', ':Markit mark delete<cr>', 'Delete Mark (Interactive)' },

        { '<leader>mb', ':Markit bookmark list all<cr>', 'All Bookmarks' },
        { '<leader>mx', ':Markit bookmark delete<cr>', 'Delete Bookmark at Cursor' },
        { '<leader>ma', ':Markit bookmark annotate<cr>', 'Annotate Bookmark' },

        { '<leader>ml', ':Markit bookmark next<cr>', 'Next Bookmark' },
        { '<leader>mh', ':Markit bookmark prev<cr>', 'Previous Bookmark' },

        { '<leader>mv', ':Markit bookmark signs<cr>', 'Toggle Signs' },

        { '<leader>mqm', ':Markit mark list quickfix all<cr>', 'All Marks → QuickFix' },
        { '<leader>mqb', ':Markit bookmark list quickfix all<cr>', 'All Bookmarks → QuickFix' },
        { '<leader>mqM', ':Markit mark list quickfix buffer<cr>', 'Buffer Marks → QuickFix' },
        { '<leader>mqg', ':Markit mark list quickfix all<cr>', 'All Marks → QuickFix' },
    }

    for i, _ in ipairs(config.bookmarks) do
        local group_index = i - 1
        table.insert(mappings, {
            string.format('<leader>m%d', group_index),
            string.format(':Markit bookmark toggle %d<cr>', group_index),
            string.format('Toggle Group %d Bookmark', group_index),
        })

        table.insert(mappings, {
            string.format('<leader>mp%d', group_index),
            string.format(':Markit bookmark prev %d<cr>', group_index),
            string.format('Previous Group %d Bookmark', group_index),
        })

        table.insert(mappings, {
            string.format('<leader>mn%d', group_index),
            string.format(':Markit bookmark next %d<cr>', group_index),
            string.format('Next Group %d Bookmark', group_index),
        })

        table.insert(mappings, {
            string.format('<leader>mg%d', group_index),
            string.format(':Markit bookmark list %d<cr>', group_index),
            string.format('Group %d Bookmarks', group_index),
        })

        table.insert(mappings, {
            string.format('<leader>mq%d', group_index),
            string.format(':Markit bookmark list quickfix %d<cr>', group_index),
            string.format('Group %d Bookmarks → QuickFix', group_index),
        })

        table.insert(mappings, {
            string.format('<leader>mc%d', group_index),
            string.format(':Markit bookmark delete %d<cr>', group_index),
            string.format('Delete Group %d Bookmarks', group_index),
        })
    end

    for _, mapping in ipairs(mappings) do
        vim.api.nvim_set_keymap('n', mapping[1], mapping[2], {
            desc = mapping[3],
            noremap = true,
            silent = true,
        })
    end
end

local function setup_highlights()
    local set_hl = vim.api.nvim_set_hl
    set_hl(0, 'MarkSignHL', { link = 'Identifier', default = true })
    set_hl(0, 'MarkSignLineHL', { link = 'NONE', default = true })
    set_hl(0, 'MarkSignNumHL', { link = 'CursorLineNr', default = true })
    set_hl(0, 'MarkVirtTextHL', { link = 'Comment', default = true })
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
    vim.api.nvim_create_user_command('Markit', markit_command, {
        nargs = '*',
        complete = complete_markit,
        desc = 'Markit commands',
    })

    if config.add_default_keybindings then
        setup_default_keybindings(config)
    end
    setup_highlights()
    setup_autocommands()
end

return M
