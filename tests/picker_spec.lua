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

    describe('entry maker functions', function()
        it('formats mark entries correctly via spy on custom_picker', function()
            local test_entry = {
                bufnr = 1,
                lnum = 10,
                col = 5,
                mark = 'a',
                line = 'Mark test line',
                path = '/test/path.txt',
            }

            local custom_picker_spy = spy.on(pickme, 'custom_picker')

            picker.marks_list_all({
                get_all_list = function()
                    return { test_entry }
                end,
            })

            vim.schedule_wrap(function()
                assert.spy(custom_picker_spy).was_called()
                local args = custom_picker_spy.calls[1].vals[1]

                local mark_entry = args.entry_maker(test_entry)

                assert.is_table(mark_entry)
                assert.equals('a', mark_entry.value.mark)
                assert.is_string(mark_entry.display)
                assert.truthy(mark_entry.display:match('Mark test line'))
                assert.truthy(mark_entry.display:match('/test/path.txt'))

                custom_picker_spy:revert()
            end)()
        end)

        it('formats bookmark entries correctly via spy on custom_picker', function()
            local test_entry = {
                bufnr = 1,
                lnum = 10,
                col = 5,
                group = 0,
                line = 'Bookmark test line',
                path = '/test/path.txt',
            }

            local custom_picker_spy = spy.on(pickme, 'custom_picker')

            picker.bookmarks_list_all({
                get_list = function()
                    return { test_entry }
                end,
            })

            vim.schedule_wrap(function()
                assert.spy(custom_picker_spy).was_called()
                local args = custom_picker_spy.calls[1].vals[1]

                local bookmark_entry = args.entry_maker(test_entry)

                assert.is_table(bookmark_entry)
                assert.equals(0, bookmark_entry.value.group)
                assert.is_string(bookmark_entry.display)
                assert.truthy(bookmark_entry.display:match('Bookmark test line'))
                assert.truthy(bookmark_entry.display:match('/test/path.txt'))

                custom_picker_spy:revert()
            end)()
        end)
    end)

    describe('file path formatting', function()
        it('formats paths correctly via spy on custom_picker', function()
            local original_fnamemodify = vim.fn.fnamemodify

            vim.fn.fnamemodify = function(path, modifier)
                if modifier == ':.' then
                    return path
                elseif modifier == ':t' then
                    return path:match('[^/]+$') or path
                elseif modifier == ':h:t' then
                    local dir = path:match('.*/([^/]+)/[^/]+$')
                    return dir or ''
                end
                return path
            end

            local short_path_entry = {
                bufnr = 1,
                lnum = 10,
                col = 5,
                mark = 'a',
                line = 'Test line',
                path = 'short/path.txt',
            }

            local long_path_entry = {
                bufnr = 1,
                lnum = 10,
                col = 5,
                mark = 'a',
                line = 'Test line',
                path = '/very/long/path/with/many/directories/and/a/filename.txt',
            }

            local empty_path_entry = {
                bufnr = 1,
                lnum = 10,
                col = 5,
                mark = 'a',
                line = 'Test line',
                path = '',
            }

            local custom_picker_spy = spy.on(pickme, 'custom_picker')

            picker.marks_list_all({
                get_all_list = function()
                    return { short_path_entry, long_path_entry, empty_path_entry }
                end,
            })

            vim.schedule_wrap(function()
                assert.spy(custom_picker_spy).was_called()
                local args = custom_picker_spy.calls[1].vals[1]

                local short_result = args.entry_maker(short_path_entry)
                local long_result = args.entry_maker(long_path_entry)
                local empty_result = args.entry_maker(empty_path_entry)

                assert.equals('short/path.txt', short_result.path)
                assert.is_string(long_result.path)
                assert.equals('[No File]', empty_result.path)

                custom_picker_spy:revert()
            end)()

            vim.fn.fnamemodify = original_fnamemodify
        end)
    end)

    describe('preview generation', function()
        it('generates previews correctly via spy on custom_picker', function()
            local original_filereadable = vim.fn.filereadable
            local original_readfile = vim.fn.readfile
            local original_match = vim.filetype.match
            local original_fs_stat = vim.loop.fs_stat

            vim.fn.filereadable = function(path)
                return path:match('/test/path') and 1 or 0
            end

            vim.fn.readfile = function(path)
                if path:match('/test/path') then
                    return {
                        'Line 1 of content',
                        'Line 2 of content',
                        'Target line is here',
                    }
                end
                return {}
            end

            vim.loop.fs_stat = function()
                return { size = 1024, mtime = { sec = os.time() } }
            end

            vim.filetype.match = function()
                return 'lua'
            end

            local test_mark_entry = {
                bufnr = 1,
                lnum = 3,
                col = 1,
                mark = 'a',
                path = '/test/path.txt',
            }

            local test_nonexistent_entry = {
                bufnr = 1,
                lnum = 1,
                col = 1,
                mark = 'a',
                path = '/nonexistent/file.txt',
            }

            local test_bookmark_entry = {
                bufnr = 1,
                lnum = 3,
                col = 1,
                group = 0,
                path = '/test/path.txt',
            }

            local custom_picker_spy = spy.on(pickme, 'custom_picker')

            picker.marks_list_all({
                get_all_list = function()
                    return { test_mark_entry }
                end,
            })

            vim.schedule_wrap(function()
                assert.spy(custom_picker_spy).was_called()
                local args = custom_picker_spy.calls[1].vals[1]

                local preview = args.preview_generator(test_mark_entry)
                local preview_nonexistent = args.preview_generator(test_nonexistent_entry)
                local preview_bookmark = args.preview_generator(test_bookmark_entry)

                assert.truthy(preview:match('```lua'))
                assert.truthy(preview:match('Target line is here'))
                assert.truthy(preview_nonexistent:match('File Not Found'))
                assert.truthy(preview_bookmark:match('Bookmark'))

                custom_picker_spy:revert()
            end)()

            vim.fn.filereadable = original_filereadable
            vim.fn.readfile = original_readfile
            vim.filetype.match = original_match
            vim.loop.fs_stat = original_fs_stat
        end)
    end)
end)
