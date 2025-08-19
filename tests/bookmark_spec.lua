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
end)
