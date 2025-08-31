local commands = require('markit.commands')
local spy = require('luassert.spy')

describe('markit.commands', function()
    local original_notify
    local notify_messages = {}

    before_each(function()
        notify_messages = {}
        original_notify = vim.notify
        vim.notify = function(msg, level)
            table.insert(notify_messages, { msg = msg, level = level })
        end
    end)

    after_each(function()
        vim.notify = original_notify
    end)

    describe('parse_args', function()
        local parse_args = commands._test_exports and commands._test_exports.parse_args

        if parse_args then
            it('splits command line arguments', function()
                local result = parse_args('mark list all')
                assert.same({ 'mark', 'list', 'all' }, result)
            end)

            it('filters empty strings', function()
                local result = parse_args('mark  list   all')
                assert.same({ 'mark', 'list', 'all' }, result)
            end)

            it('handles empty input', function()
                local result = parse_args('')
                assert.same({}, result)
            end)
        end
    end)

    describe('filter_by_prefix', function()
        local filter_by_prefix = commands._test_exports and commands._test_exports.filter_by_prefix

        if filter_by_prefix then
            it('filters items by prefix', function()
                local items = { 'mark', 'bookmark', 'buffer' }
                local result = filter_by_prefix(items, 'b')
                assert.same({ 'bookmark', 'buffer' }, result)
            end)

            it('returns empty for no matches', function()
                local items = { 'mark', 'bookmark' }
                local result = filter_by_prefix(items, 'x')
                assert.same({}, result)
            end)
        end
    end)

    describe('get_completion_options', function()
        local get_completion_options = commands._test_exports and commands._test_exports.get_completion_options

        if get_completion_options then
            it('returns domains', function()
                local result = get_completion_options('domains')
                assert.same({ 'mark', 'bookmark' }, result)
            end)

            it('returns mark actions', function()
                local result = get_completion_options('mark_actions')
                assert.contains(result, 'list')
                assert.contains(result, 'toggle')
                assert.contains(result, 'preview')
            end)

            it('returns bookmark actions', function()
                local result = get_completion_options('bookmark_actions')
                assert.contains(result, 'list')
                assert.contains(result, 'signs')
                assert.contains(result, 'annotate')
            end)

            it('adds bookmark groups dynamically', function()
                local result = get_completion_options('bookmark_list_scopes')
                assert.contains(result, '0')
                assert.contains(result, '9')
                assert.contains(result, 'buffer')
            end)
        end
    end)

    describe('command setup', function()
        it('sets up Markit command successfully', function()
            commands.setup({ add_default_keybindings = false })
            local cmd_info = vim.api.nvim_get_commands({})['Markit']
            assert.is_not_nil(cmd_info)
            assert.equals('Markit commands', cmd_info.definition)
        end)

        it('sets up completion function', function()
            commands.setup({ add_default_keybindings = false })
            local cmd_info = vim.api.nvim_get_commands({})['Markit']
            assert.is_not_nil(cmd_info)
            assert.is_not_nil(cmd_info.complete)
        end)
    end)
end)
