local bookmark = require('markit.bookmark')
local spy = require('luassert.spy')

describe('markit.bookmark', function()
    local bookmark_state

    before_each(function()
        bookmark_state = bookmark.new()
        bookmark_state.opt = {
            priority = 20,
            signs = true,
        }
        bookmark_state.signs = { '!', '@', '#', '$', '%', '^', '&', '*', '(', [0] = ')' }
        bookmark_state.virt_text = { 'hello' }
        bookmark_state.groups = {}
        bookmark_state.priority = 20
        bookmark_state.prompt_annotate = {}
    end)

    describe('place_mark', function()
        it('validates column position', function()
            local bufnr = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'short line' })

            bookmark_state.opt.buf_signs = {}

            local utils = require('markit.utils')
            local set_extmark_spy = spy.on(utils, 'safe_set_extmark')

            bookmark_state:place_mark(0, bufnr, { 1, 0 })

            assert.spy(set_extmark_spy).was_called()

            set_extmark_spy:revert()
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end)

        it('handles invalid buffers gracefully', function()
            local utils = require('markit.utils')
            local is_valid_spy = spy.on(utils, 'is_valid_buffer', function()
                return false
            end)

            bookmark_state:place_mark(0, 9999)

            assert.spy(is_valid_spy).was_called()

            is_valid_spy:revert()
        end)
    end)

    describe('to_list', function()
        it('filters out invalid buffers', function()
            local group_nr = 0
            bookmark_state:init(group_nr)

            local invalid_bufnr = 9999
            bookmark_state.groups[group_nr].marks[invalid_bufnr] = {
                ['1_1'] = { line = 1, col = 0, id = 1 },
            }

            local utils = require('markit.utils')
            spy.on(utils, 'choose_list', function()
                return function() end
            end)

            bookmark_state:to_list('quickfixlist', group_nr)

            assert.is_nil(bookmark_state.groups[group_nr].marks[invalid_bufnr])
        end)

        it('uses safe buffer operations', function()
            local group_nr = 0
            bookmark_state:init(group_nr)

            local bufnr = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'Test line' })

            bookmark_state.groups[group_nr].marks[bufnr] = {
                ['1_1'] = { line = 1, col = 0, id = 1 },
            }

            local utils = require('markit.utils')
            local safe_get_line_spy = spy.on(utils, 'safe_get_line')
            spy.on(utils, 'choose_list', function()
                return function() end
            end)

            bookmark_state:to_list('quickfixlist', group_nr)

            assert.spy(safe_get_line_spy).was_called()

            safe_get_line_spy:revert()
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end)
    end)

    describe('project functionality', function()
        local utils = require('markit.utils')
        local original_get_git_root

        before_each(function()
            original_get_git_root = utils.get_git_root
        end)

        after_each(function()
            utils.get_git_root = original_get_git_root
        end)

        describe('get_project_list', function()
            it('calls get_list with project=true', function()
                local get_list_spy = spy.on(bookmark_state, 'get_list')
                local refresh_spy = spy.on(bookmark_state, 'refresh')

                bookmark_state:get_project_list()

                assert.spy(refresh_spy).was_called()
                assert.spy(get_list_spy).was_called_with(bookmark_state, { project = true })

                get_list_spy:revert()
                refresh_spy:revert()
            end)
        end)

        describe('get_buffer_list', function()
            it('calls get_list with buffer filter', function()
                local bufnr = vim.api.nvim_create_buf(false, true)
                local get_list_spy = spy.on(bookmark_state, 'get_list')
                local refresh_spy = spy.on(bookmark_state, 'refresh')

                bookmark_state:get_buffer_list(bufnr)

                assert.spy(refresh_spy).was_called()
                assert.spy(get_list_spy).was_called_with(bookmark_state, { buffer = bufnr })

                get_list_spy:revert()
                refresh_spy:revert()
                vim.api.nvim_buf_delete(bufnr, { force = true })
            end)
        end)

        describe('project_to_list', function()
            it('shows warning when not in git repository', function()
                local original_notify = vim.notify
                local notify_spy = spy.on(vim, 'notify')
                utils.get_git_root = function()
                    return nil
                end

                bookmark_state:project_to_list()

                assert.spy(notify_spy).was_called_with('Not in a git repository', vim.log.levels.WARN)

                notify_spy:revert()
                vim.notify = original_notify
            end)
        end)
    end)
end)
