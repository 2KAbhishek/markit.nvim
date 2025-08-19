local picker = require('markit.picker')
local spy = require('luassert.spy')

describe('markit.picker', function()
    local pickme
    local config

    before_each(function()
        pickme = require('pickme')
        config = require('markit.config')

        config.config = {
            icons = {
                file = '',
                target = '▶',
                error = '✗',
                content_separator = '-',
                line_separator = '│',
                marks = {
                    buffer = 'b',
                    global = 'g',
                    numbered = '#',
                    default = '*',
                    last_jump = 'j',
                    last_insert = 'i',
                    last_change = 'c',
                    visual_start = '<',
                    visual_end = '>',
                },
                default_bookmark = '★',
            },
            bookmarks = {
                { sign = '⚑', virt_text = 'bookmark 0' },
                { sign = '!', virt_text = 'bookmark 1' },
            },
            preview = {
                context_before = 5,
                context_after = 10,
            },
        }
    end)

    describe('marks_list_all', function()
        it('calls pickme.custom_picker with correct parameters', function()
            local mark_state = {
                get_all_list = function()
                    return {
                        {
                            bufnr = 1,
                            lnum = 10,
                            col = 5,
                            mark = 'a',
                            line = 'Test line',
                            path = '/test/path.txt',
                        },
                    }
                end,
            }

            local custom_picker_spy = spy.on(pickme, 'custom_picker')

            picker.marks_list_all(mark_state)
            vim.schedule_wrap(function()
                assert.spy(custom_picker_spy).was_called()
                local args = custom_picker_spy.calls[1].vals[1]

                assert.equals('All Marks', args.title)
                assert.equals('markdown', args.preview_ft)
                assert.equals(1, #args.items)
                assert.is_function(args.entry_maker)
                assert.is_function(args.preview_generator)
                assert.is_function(args.selection_handler)

                custom_picker_spy:revert()
            end)()
        end)

        it('shows notification when no marks found', function()
            local mark_state = {
                get_all_list = function()
                    return {}
                end,
            }

            local notify_spy = spy.on(vim, 'notify')

            picker.marks_list_all(mark_state)

            assert.spy(notify_spy).was_called_with('No marks found', vim.log.levels.INFO)

            notify_spy:revert()
        end)
    end)

    describe('marks_list_buf', function()
        it('calls pickme.custom_picker with correct parameters', function()
            local mark_state = {
                get_buf_list = function()
                    return {
                        {
                            bufnr = 1,
                            lnum = 10,
                            col = 5,
                            mark = 'a',
                            line = 'Test line',
                            path = '/test/path.txt',
                        },
                    }
                end,
            }

            local custom_picker_spy = spy.on(pickme, 'custom_picker')

            picker.marks_list_buf(mark_state)
            vim.schedule_wrap(function()
                assert.spy(custom_picker_spy).was_called()
                local args = custom_picker_spy.calls[1].vals[1]

                assert.equals('Buffer Marks', args.title)
                assert.equals('markdown', args.preview_ft)
                assert.equals(1, #args.items)
                assert.is_function(args.entry_maker)
                assert.is_function(args.preview_generator)
                assert.is_function(args.selection_handler)

                custom_picker_spy:revert()
            end)()
        end)
    end)

    describe('bookmarks_list_all', function()
        it('calls pickme.custom_picker with correct parameters', function()
            local bookmark_state = {
                get_list = function()
                    return {
                        {
                            bufnr = 1,
                            lnum = 10,
                            col = 5,
                            group = 0,
                            line = 'Test line',
                            path = '/test/path.txt',
                        },
                    }
                end,
            }

            local custom_picker_spy = spy.on(pickme, 'custom_picker')

            picker.bookmarks_list_all(bookmark_state)
            vim.schedule_wrap(function()
                assert.spy(custom_picker_spy).was_called()
                local args = custom_picker_spy.calls[1].vals[1]

                assert.equals('All Bookmarks', args.title)
                assert.equals('markdown', args.preview_ft)
                assert.equals(1, #args.items)
                assert.is_function(args.entry_maker)
                assert.is_function(args.preview_generator)
                assert.is_function(args.selection_handler)

                custom_picker_spy:revert()
            end)()
        end)
    end)

    describe('bookmarks_list_group', function()
        it('calls pickme.custom_picker with correct parameters', function()
            local bookmark_state = {
                get_list = function()
                    return {
                        {
                            bufnr = 1,
                            lnum = 10,
                            col = 5,
                            group = 0,
                            line = 'Test line',
                            path = '/test/path.txt',
                        },
                    }
                end,
            }

            local custom_picker_spy = spy.on(pickme, 'custom_picker')

            picker.bookmarks_list_group(bookmark_state, 0)
            vim.schedule_wrap(function()
                assert.spy(custom_picker_spy).was_called()
                local args = custom_picker_spy.calls[1].vals[1]

                assert.equals('Bookmark Group 0', args.title)
                assert.equals('markdown', args.preview_ft)
                assert.equals(1, #args.items)
                assert.is_function(args.entry_maker)
                assert.is_function(args.preview_generator)
                assert.is_function(args.selection_handler)

                custom_picker_spy:revert()
            end)()
        end)
    end)

    describe('picker functionality', function()
        it('has functions to list marks and bookmarks', function()
            assert.is_function(picker.marks_list_all)
            assert.is_function(picker.marks_list_buf)
            assert.is_function(picker.bookmarks_list_all)
            assert.is_function(picker.bookmarks_list_group)
        end)
    end)
end)
