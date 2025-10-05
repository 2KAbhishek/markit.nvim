local config_module = require('markit.config')

describe('markit.config', function()
    local original_config

    before_each(function()
        original_config = vim.deepcopy(config_module.config)
    end)

    after_each(function()
        config_module.config = original_config
    end)

    describe('setup', function()
        it('uses default config when no options provided', function()
            config_module.setup()
            assert.is_table(config_module.config)
            assert.is_true(config_module.config.add_default_keybindings)
            assert.is_table(config_module.config.sign_priority)
        end)

        it('merges user config with defaults', function()
            local user_config = {
                add_default_keybindings = false,
                signs = false,
            }

            config_module.setup(user_config)

            assert.is_false(config_module.config.add_default_keybindings)
            assert.is_false(config_module.config.signs)
            assert.is_true(config_module.config.cyclic)
        end)

        it('deep merges nested config values', function()
            local user_config = {
                sign_priority = {
                    lower = 20,
                },
                icons = {
                    file = '📄',
                },
            }

            config_module.setup(user_config)

            assert.equals(20, config_module.config.sign_priority.lower)
            assert.equals(15, config_module.config.sign_priority.upper)
            assert.equals('📄', config_module.config.icons.file)
        end)

        it('has enable_bookmarks option with default true', function()
            config_module.setup()
            assert.is_true(config_module.config.enable_bookmarks)
        end)

        it('allows disabling bookmarks via enable_bookmarks option', function()
            local user_config = {
                enable_bookmarks = false,
            }

            config_module.setup(user_config)

            assert.is_false(config_module.config.enable_bookmarks)
        end)
    end)
end)
