local markit = require('markit')

describe('markit', function()
    before_each(function()
        for name, _ in pairs(package.loaded) do
            if name:match('^markit') then
                package.loaded[name] = nil
            end
        end

        vim.api.nvim_command('silent! %bwipeout!')

        if vim.fn.exists(':delcommand Markit') == 2 then
            vim.cmd('delcommand Markit')
        end

        vim.cmd('augroup Marks_autocmds | autocmd! | augroup END')
    end)

    after_each(function()
        if markit.bookmark_state and markit.bookmark_state.groups then
            for _, group in pairs(markit.bookmark_state.groups) do
                if group.ns then
                    vim.api.nvim_buf_clear_namespace(0, group.ns, 0, -1)
                end
            end
        end

        if markit.mark_state and markit.mark_state.ns then
            vim.api.nvim_buf_clear_namespace(0, markit.mark_state.ns, 0, -1)
        end
    end)

    it('passes test', function()
        assert(1 == 1)
    end)

    describe('setup with enable_bookmarks', function()
        before_each(function()
            markit.bookmark_state = nil
            markit.mark_state = nil
        end)

        it('initializes bookmark_state when enable_bookmarks is true', function()
            markit.setup({ enable_bookmarks = true })
            assert.is_not_nil(markit.bookmark_state)
        end)

        it('does not initialize bookmark_state when enable_bookmarks is false', function()
            markit.setup({ enable_bookmarks = false })
            assert.is_nil(markit.bookmark_state)
        end)

        it('initializes mark_state regardless of enable_bookmarks setting', function()
            markit.setup({ enable_bookmarks = false })
            assert.is_not_nil(markit.mark_state)

            markit.setup({ enable_bookmarks = true })
            assert.is_not_nil(markit.mark_state)
        end)
    end)
end)
