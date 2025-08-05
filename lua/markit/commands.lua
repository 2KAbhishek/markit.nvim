local M = {}

function M.setup_default_keybindings()
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

    for i = 0, 9 do
        table.insert(mappings, {
            string.format('<leader>m%d', i),
            string.format(':lua require("markit").toggle_bookmark%d()<cr>', i),
            string.format('Toggle Group %d Bookmark', i),
        })

        table.insert(mappings, {
            string.format('<leader>mp%d', i),
            string.format(':lua require("markit").prev_bookmark%d()<cr>', i),
            string.format('Previous Group %d Bookmark', i),
        })

        table.insert(mappings, {
            string.format('<leader>mn%d', i),
            string.format(':lua require("markit").next_bookmark%d()<cr>', i),
            string.format('Next Group %d Bookmark', i),
        })

        table.insert(mappings, {
            string.format('<leader>mg%d', i),
            string.format(':lua require("markit").bookmarks_list_group(%d)<cr>', i),
            string.format('Group %d Bookmarks', i),
        })

        table.insert(mappings, {
            string.format('<leader>mq%d', i),
            string.format(':BookmarksQFList %d<cr>', i),
            string.format('Group %d Bookmarks → QuickFix', i),
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

return M
