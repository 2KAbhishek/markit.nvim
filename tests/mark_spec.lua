local mark = require('markit.mark')
local spy = require('luassert.spy')

describe('markit.mark', function()
    local mark_state

    before_each(function()
        mark_state = mark.new()
        mark_state.opt = {
            signs = true,
            cyclic = true,
            priority = { 10, 15, 8 },
            buf_signs = {},
            builtin_marks = {},
            force_write_shada = false,
        }
        mark_state.buffers = {}
        mark_state.builtin_marks = {}
    end)

    describe('refresh', function()
        it('handles invalid buffer gracefully', function()
            local invalid_bufnr = 9999
            mark_state.buffers[invalid_bufnr] = {
                placed_marks = { a = { line = 1, col = 0, id = -1 } },
                marks_by_line = { [1] = { 'a' } },
                lowest_available_mark = 'b',
            }

            mark_state:refresh(invalid_bufnr)

            assert.is_nil(mark_state.buffers[invalid_bufnr])
        end)

        it('initializes buffer state if not exists', function()
            local bufnr = vim.api.nvim_create_buf(false, true)

            mark_state:refresh(bufnr)

            assert.is_table(mark_state.buffers[bufnr])
            assert.is_table(mark_state.buffers[bufnr].placed_marks)
            assert.is_table(mark_state.buffers[bufnr].marks_by_line)
            assert.equals('a', mark_state.buffers[bufnr].lowest_available_mark)

            vim.api.nvim_buf_delete(bufnr, { force = true })
        end)
    end)

    describe('get_all_list', function()
        it('cleans up invalid buffers', function()
            local invalid_bufnr = 9999
            mark_state.buffers[invalid_bufnr] = {
                placed_marks = { a = { line = 1, col = 0, id = -1 } },
                marks_by_line = { [1] = { 'a' } },
                lowest_available_mark = 'b',
            }

            local valid_bufnr = vim.api.nvim_create_buf(false, true)
            mark_state.buffers[valid_bufnr] = {
                placed_marks = { b = { line = 1, col = 0, id = -1 } },
                marks_by_line = { [1] = { 'b' } },
                lowest_available_mark = 'c',
            }

            local results = mark_state:get_all_list()

            assert.is_nil(mark_state.buffers[invalid_bufnr])
            assert.is_table(mark_state.buffers[valid_bufnr])
            assert.equals(1, #results)
            assert.equals('b', results[1].mark)
            assert.equals(valid_bufnr, results[1].bufnr)

            vim.api.nvim_buf_delete(valid_bufnr, { force = true })
        end)
    end)

    describe('delete_mark', function()
        it('returns early for invalid buffers', function()
            local invalid_bufnr = 9999
            local current_buf_spy = spy.on(vim.api, 'nvim_get_current_buf', function()
                return invalid_bufnr
            end)
            local utils = require('markit.utils')
            local is_valid_spy = spy.on(utils, 'is_valid_buffer', function()
                return false
            end)

            mark_state:delete_mark('a')

            assert.spy(is_valid_spy).was_called()
            assert.spy(current_buf_spy).was_called()

            is_valid_spy:revert()
            current_buf_spy:revert()
        end)
    end)
end)
