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

    describe('project functionality', function()
        local utils = require('markit.utils')
        local original_get_git_root
        local original_notify

        before_each(function()
            original_get_git_root = utils.get_git_root
            original_notify = vim.notify
            vim.notify = function() end
        end)

        after_each(function()
            utils.get_git_root = original_get_git_root
            vim.notify = original_notify
        end)

        describe('delete_project_marks', function()
            it('shows warning when not in git repository', function()
                local notify_spy = spy.on(vim, 'notify')
                utils.get_git_root = function()
                    return nil
                end

                mark_state:delete_project_marks()

                assert.spy(notify_spy).was_called_with('Not in a git repository', vim.log.levels.WARN)
                notify_spy:revert()
            end)

            it('deletes marks in git repository', function()
                local git_root = '/home/user/project/'
                utils.get_git_root = function()
                    return git_root
                end

                local bufnr = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_name(bufnr, '/home/user/project/file.lua')

                mark_state.buffers[bufnr] = {
                    placed_marks = { a = { line = 1, col = 0, id = -1 } },
                    marks_by_line = { [1] = { 'a' } },
                    lowest_available_mark = 'b',
                }

                local cmd_spy = spy.on(vim, 'cmd')
                local buf_call_spy = spy.on(vim.api, 'nvim_buf_call')

                mark_state:delete_project_marks()

                assert.same({
                    placed_marks = {},
                    marks_by_line = {},
                    lowest_available_mark = 'a',
                }, mark_state.buffers[bufnr])

                assert.spy(buf_call_spy).was_called()

                cmd_spy:revert()
                buf_call_spy:revert()
                vim.api.nvim_buf_delete(bufnr, { force = true })
            end)

            it('ignores files outside git repository', function()
                local git_root = '/home/user/project/'
                utils.get_git_root = function()
                    return git_root
                end

                local bufnr = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_name(bufnr, '/home/user/other/file.lua')

                local original_marks = {
                    placed_marks = { a = { line = 1, col = 0, id = -1 } },
                    marks_by_line = { [1] = { 'a' } },
                    lowest_available_mark = 'b',
                }
                mark_state.buffers[bufnr] = vim.deepcopy(original_marks)

                mark_state:delete_project_marks()

                assert.same(original_marks, mark_state.buffers[bufnr])

                vim.api.nvim_buf_delete(bufnr, { force = true })
            end)
        end)

        describe('get_project_list', function()
            it('filters marks by git root', function()
                local git_root = '/home/user/project/'

                local bufnr1 = vim.api.nvim_create_buf(false, true)
                local bufnr2 = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_name(bufnr1, '/home/user/project/file1.lua')
                vim.api.nvim_buf_set_name(bufnr2, '/home/user/other/file2.lua')
                vim.api.nvim_buf_set_lines(bufnr1, 0, -1, false, { 'line in project' })
                vim.api.nvim_buf_set_lines(bufnr2, 0, -1, false, { 'line outside project' })

                mark_state.buffers[bufnr1] = {
                    placed_marks = { a = { line = 1, col = 0, id = -1 } },
                    marks_by_line = { [1] = { 'a' } },
                    lowest_available_mark = 'b',
                }
                mark_state.buffers[bufnr2] = {
                    placed_marks = { b = { line = 1, col = 0, id = -1 } },
                    marks_by_line = { [1] = { 'b' } },
                    lowest_available_mark = 'c',
                }

                local results = mark_state:get_project_list(git_root)

                assert.equals(1, #results)
                assert.equals('a', results[1].mark)
                assert.equals(bufnr1, results[1].bufnr)
                assert.equals('line in project', results[1].line)

                vim.api.nvim_buf_delete(bufnr1, { force = true })
                vim.api.nvim_buf_delete(bufnr2, { force = true })
            end)

            it('returns all marks when no git_root provided', function()
                local bufnr = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'test line' })

                mark_state.buffers[bufnr] = {
                    placed_marks = { a = { line = 1, col = 0, id = -1 } },
                    marks_by_line = { [1] = { 'a' } },
                    lowest_available_mark = 'b',
                }

                local results = mark_state:get_project_list(nil)

                assert.equals(1, #results)
                assert.equals('a', results[1].mark)

                vim.api.nvim_buf_delete(bufnr, { force = true })
            end)
        end)

        describe('project_to_list', function()
            it('shows warning when not in git repository', function()
                local notify_spy = spy.on(vim, 'notify')
                utils.get_git_root = function()
                    return nil
                end

                mark_state:project_to_list()

                assert.spy(notify_spy).was_called_with('Not in a git repository', vim.log.levels.WARN)
                notify_spy:revert()
            end)
        end)
    end)
end)
