local M = {}



local function setup_default_keybindings(config)
    local mappings = {
        { '<leader>mm', ':lua require("markit").marks_list_all()<cr>', 'All Marks' },
        { '<leader>mM', ':lua require("markit").marks_list_buf()<cr>', 'Buffer Marks' },
        { '<leader>ms', ':lua require("markit").set_next()<cr>', 'Set Next Available Mark' },
        { '<leader>mS', ':lua require("markit").set()<cr>', 'Set Mark (Interactive)' },
        { '<leader>mt', ':lua require("markit").toggle()<cr>', 'Toggle Mark at Cursor' },
        { '<leader>mT', ':lua require("markit").toggle_mark()<cr>', 'Toggle Mark (Interactive)' },

        { '<leader>mj', ':lua require("markit").next()<cr>', 'Next Mark' },
        { '<leader>mk', ':lua require("markit").prev()<cr>', 'Previous Mark' },
        { '<leader>mP', ':lua require("markit").preview()<cr>', 'Preview Mark' },

        { '<leader>md', ':lua require("markit").delete_line()<cr>', 'Delete Marks In Line' },
        { '<leader>mD', ':lua require("markit").delete_buf()<cr>', 'Delete Marks In Buffer' },
        { '<leader>mX', ':lua require("markit").delete()<cr>', 'Delete Mark (Interactive)' },

        { '<leader>mb', ':lua require("markit").bookmarks_list_all()<cr>', 'All Bookmarks' },
        { '<leader>mx', ':lua require("markit").delete_bookmark()<cr>', 'Delete Bookmark at Cursor' },
        { '<leader>ma', ':lua require("markit").annotate()<cr>', 'Annotate Bookmark' },

        { '<leader>ml', ':lua require("markit").next_bookmark()<cr>', 'Next Bookmark' },
        { '<leader>mh', ':lua require("markit").prev_bookmark()<cr>', 'Previous Bookmark' },

        { '<leader>mv', ':lua require("markit").toggle_signs()<cr>', 'Toggle Signs' },

        { '<leader>mqm', ':MarksQFListAll<cr>', 'All Marks → QuickFix' },
        { '<leader>mqb', ':BookmarksQFListAll<cr>', 'All Bookmarks → QuickFix' },
        { '<leader>mqM', ':MarksQFListBuf<cr>', 'Buffer Marks → QuickFix' },
        { '<leader>mqg', ':MarksQFListGlobal<cr>', 'Global Marks → QuickFix' },
    }

    for i, _ in ipairs(config.bookmarks) do
        local group_index = i - 1
        table.insert(mappings, {
            string.format('<leader>m%d', group_index),
            string.format(':lua require("markit").toggle_bookmark%d()<cr>', group_index),
            string.format('Toggle Group %d Bookmark', group_index),
        })

        table.insert(mappings, {
            string.format('<leader>mp%d', group_index),
            string.format(':lua require("markit").prev_bookmark%d()<cr>', group_index),
            string.format('Previous Group %d Bookmark', group_index),
        })

        table.insert(mappings, {
            string.format('<leader>mn%d', group_index),
            string.format(':lua require("markit").next_bookmark%d()<cr>', group_index),
            string.format('Next Group %d Bookmark', group_index),
        })

        table.insert(mappings, {
            string.format('<leader>mg%d', group_index),
            string.format(':lua require("markit").bookmarks_list_group(%d)<cr>', group_index),
            string.format('Group %d Bookmarks', group_index),
        })

        table.insert(mappings, {
            string.format('<leader>mq%d', group_index),
            string.format(':BookmarksQFList %d<cr>', group_index),
            string.format('Group %d Bookmarks → QuickFix', group_index),
        })

        table.insert(mappings, {
            string.format('<leader>mc%d', group_index),
            string.format(':lua require("markit").delete_bookmark%d()<cr>', group_index),
            string.format('Clear Group %d Bookmarks', group_index),
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

local function setup_commands()
    local add_user_command = vim.api.nvim_create_user_command
    add_user_command('MarksToggleSigns', function(opts)
        require('markit').toggle_signs(opts.args)
    end, { nargs = '?' })

    add_user_command('MarksListBuf', function()
        require('markit').marks_list_buf()
    end, {})

    add_user_command('MarksListGlobal', function()
        require('markit').marks_list_all()
    end, {})

    add_user_command('MarksListAll', function()
        require('markit').marks_list_all()
    end, {})

    add_user_command('MarksQFListBuf', function()
        require('markit').mark_state:buffer_to_list('quickfixlist')
        vim.cmd('copen')
    end, {})

    add_user_command('MarksQFListGlobal', function()
        require('markit').mark_state:global_to_list('quickfixlist')
        vim.cmd('copen')
    end, {})

    add_user_command('MarksQFListAll', function()
        require('markit').mark_state:all_to_list('quickfixlist')
        vim.cmd('copen')
    end, {})

    add_user_command('BookmarksList', function(opts)
        local group_nr = tonumber(opts.args)
        if group_nr then
            require('markit').bookmarks_list_group(group_nr)
        else
            require('markit').bookmarks_list_all()
        end
    end, { nargs = '?' })

    add_user_command('BookmarksListAll', function()
        require('markit').bookmarks_list_all()
    end, {})

    add_user_command('BookmarksQFList', function(opts)
        require('markit').bookmark_state:to_list('quickfixlist', tonumber(opts.args))
        vim.cmd('copen')
    end, { nargs = 1 })

    add_user_command('BookmarksQFListAll', function()
        require('markit').bookmark_state:all_to_list('quickfixlist')
        vim.cmd('copen')
    end, {})
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
    setup_commands()
    if config.add_default_keybindings then
        setup_default_keybindings(config)
    end
    setup_highlights()
    setup_autocommands()
end

return M
