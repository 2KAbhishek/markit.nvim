vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

vim.cmd('set shortmess+=F')

local temp_dir = vim.fn.tempname()
vim.fn.mkdir(temp_dir, 'p')

vim.opt.directory = temp_dir
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.shadafile = 'NONE'
vim.opt.undofile = false

local plenary_dir = os.getenv('PLENARY_DIR') or '/tmp/plenary.nvim'
local is_not_a_directory = vim.fn.isdirectory(plenary_dir) == 0
if is_not_a_directory then
    vim.fn.system({ 'git', 'clone', 'https://github.com/nvim-lua/plenary.nvim', plenary_dir })
end

vim.opt.rtp:append('.')
vim.opt.rtp:append(plenary_dir)

vim.cmd('runtime plugin/plenary.vim')
require('plenary.busted')

package.loaded['pickme'] = {
    custom_picker = function()
        return true
    end,
}

vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
        vim.fn.delete(temp_dir, 'rf')
    end,
})
