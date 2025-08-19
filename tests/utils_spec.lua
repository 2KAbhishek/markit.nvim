local utils = require('markit.utils')

describe('markit.utils', function()
    before_each(function()
        utils.buffer_valid_cache = {}
        utils.path_cache = {}
        utils.filetype_cache = {}
    end)

    describe('is_valid_buffer', function()
        it('returns false for nil buffer', function()
            assert.is_false(utils.is_valid_buffer(nil))
        end)

        it('caches buffer validation results', function()
            local bufnr = vim.api.nvim_create_buf(false, true)

            assert.is_true(utils.is_valid_buffer(bufnr))
            assert.is_true(utils.buffer_valid_cache[bufnr])

            local cached_value = utils.buffer_valid_cache[bufnr]
            utils.buffer_valid_cache[bufnr] = false

            assert.is_false(utils.is_valid_buffer(bufnr))

            vim.api.nvim_buf_delete(bufnr, { force = true })
        end)
    end)

    describe('invalidate_buffer', function()
        it('clears cached buffer data', function()
            local bufnr = vim.api.nvim_create_buf(false, true)

            utils.buffer_valid_cache[bufnr] = true
            utils.path_cache[bufnr] = '/some/path'

            utils.invalidate_buffer(bufnr)

            assert.is_nil(utils.buffer_valid_cache[bufnr])
            assert.is_nil(utils.path_cache[bufnr])

            vim.api.nvim_buf_delete(bufnr, { force = true })
        end)
    end)

    describe('clear_caches', function()
        it('clears all caches', function()
            utils.buffer_valid_cache = { [1] = true }
            utils.path_cache = { [1] = '/some/path' }
            utils.filetype_cache = { ['/some/path'] = 'lua' }

            utils.clear_caches()

            assert.same({}, utils.buffer_valid_cache)
            assert.same({}, utils.path_cache)
            assert.same({}, utils.filetype_cache)
        end)
    end)

    describe('validate_column', function()
        it('returns 0 for empty lines', function()
            local bufnr = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '' })

            assert.equals(0, utils.validate_column(bufnr, 0, 5))

            vim.api.nvim_buf_delete(bufnr, { force = true })
        end)

        it('clamps column to line length', function()
            local bufnr = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '1234' })

            assert.equals(4, utils.validate_column(bufnr, 0, 10))
            assert.equals(2, utils.validate_column(bufnr, 0, 2))

            vim.api.nvim_buf_delete(bufnr, { force = true })
        end)
    end)

    describe('safe_set_extmark', function()
        it('returns -1 for invalid buffers', function()
            assert.equals(-1, utils.safe_set_extmark(9999, 1, 0, 0))
        end)

        it('validates column position', function()
            local bufnr = vim.api.nvim_create_buf(false, true)
            local ns_id = vim.api.nvim_create_namespace('test_namespace')
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '1234' })

            local mark_id = utils.safe_set_extmark(bufnr, ns_id, 0, 10, {})

            assert.is_true(mark_id > 0)

            local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, ns_id, 0, -1, {})
            assert.equals(1, #extmarks)
            local _, row, col = unpack(extmarks[1])

            assert.equals(0, row)
            assert.equals(4, col)

            vim.api.nvim_buf_delete(bufnr, { force = true })
        end)
    end)
end)
