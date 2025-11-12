-- ================================
-- 💤 General Neovim Configuration
-- ================================

-- Leader Keys
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- UI Settings
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = 'yes'
vim.opt.scrolloff = 16
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.showmode = false
vim.opt.breakindent = true
vim.opt.confirm = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 500

-- Indentation
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartcase = true
vim.opt.ignorecase = true

-- Mouse & Clipboard
vim.opt.mouse = 'a'
vim.schedule(function()
    vim.opt.clipboard = 'unnamedplus'
end)

-- Splits
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Undo / History
vim.opt.undofile = true

-- Command-line Behavior
vim.opt.inccommand = 'split'

-- Shell Settings (Windows PowerShell)
vim.opt.shell = 'powershell'
vim.opt.shellcmdflag = '-NoProfile -ExecutionPolicy RemoteSigned -Command'
vim.opt.shellquote = '"'
vim.opt.shellxquote = ''

-- Nerd Font Indicator
vim.g.have_nerd_font = true

-- ====================
-- 🔑 Key Mappings
-- ====================

-- Basic navigation
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down and center cursor' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up and center cursor' })

-- Saving
vim.keymap.set({ 'n', 'i' }, '<C-s>', '<Esc><cmd>w<CR>', { desc = 'Save file' })

-- Quickfix
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostics → Quickfix' })
vim.keymap.set('n', '<C-j>', '<cmd>cnext<CR>', { desc = 'Next quickfix item' })
vim.keymap.set('n', '<C-k>', '<cmd>cprev<CR>', { desc = 'Previous quickfix item' })
vim.keymap.set('n', '<C-q>', '<cmd>copen<CR>', { desc = 'Open quickfix list' })

-- Splits
vim.keymap.set('n', '<C-w>v', '<cmd>vsplit<CR>')
vim.keymap.set('n', '<C-w>s', '<cmd>split<CR>')

-- resize splits
vim.keymap.set('n', '<C-Left>', '<cmd>vertical resize -5<CR>', { desc = 'Resize split left' })
vim.keymap.set('n', '<C-Right>', '<cmd>vertical resize +5<CR>', { desc = 'Resize split right' })
vim.keymap.set('n', '<C-Up>', '<cmd>resize +5<CR>', { desc = 'Resize split up' })
vim.keymap.set('n', '<C-Down>', '<cmd>resize -5<CR>', { desc = 'Resize split down' })

-- Visual mode tweaks
vim.keymap.set('v', '>', '>gv', { desc = 'Indent and keep selection' })
vim.keymap.set('v', '<', '<gv', { desc = 'Unindent and keep selection' })
vim.keymap.set('v', '<leader>s', ':sort<CR>', { desc = 'Sort selected lines' })

-- Terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Oil
vim.keymap.set('n', '<leader>e', '<CMD>Oil<CR>', { desc = 'Open parent directory' })

-- Helper to get a unique session path based on current repo or folder
local function get_session_path()
    local git_output = vim.fn.systemlist 'git rev-parse --show-toplevel'
    local git_root = vim.v.shell_error == 0 and git_output[1] or nil
    local base = git_root or vim.loop.cwd()

    local session_dir = vim.fn.stdpath 'data' .. '\\sessions'
    vim.fn.mkdir(session_dir, 'p')

    local session_name = base:gsub(':', ''):gsub('\\', '_'):gsub('/', '_')
    return session_dir .. '\\' .. session_name .. '.vim'
end

-- 💾 Save session
vim.keymap.set('n', '<leader>ss', function()
    local session_path = get_session_path()
    vim.cmd('mksession! ' .. vim.fn.fnameescape(session_path))
    vim.notify('💾 Session saved: ' .. session_path, vim.log.levels.INFO)
end, { desc = 'Save session for current repo' })
-- 🔄 Load session
vim.keymap.set('n', '<leader>sl', function()
    local session_path = get_session_path()
    if vim.fn.filereadable(session_path) == 1 then
        vim.cmd('source ' .. vim.fn.fnameescape(session_path))
        vim.notify('🔄 Session loaded: ' .. session_path, vim.log.levels.INFO)
    else
        vim.notify('⚠️ No session found for this repo', vim.log.levels.WARN)
    end
end, { desc = 'Load session for current repo' })

-- Build .NET projects
vim.keymap.set('n', '<C-b>', function()
    print 'Building...'
    local output = vim.fn.systemlist 'dotnet build -nologo -consoleloggerparameters:NoSummary'
    local exit_code = vim.v.shell_error

    local errors = vim.tbl_filter(function(line)
        return line:match 'error'
    end, output)

    vim.fn.setqflist({}, 'r', { title = 'dotnet build errors', lines = errors })
    if #errors > 0 or exit_code ~= 0 then
        vim.cmd 'copen'
    else
        vim.cmd 'cclose'
        print '✅ Build succeeded'
    end
end, { desc = 'Build .NET project' })

-- Git helpers
vim.keymap.set('n', '<leader>gb', function()
    local relpath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':.')
    local line = vim.fn.line '.'
    local cmd = string.format('git log -1 -L %d,%d:%s --no-patch --format="%%an | %%s | %%cr"', line, line, relpath)
    local output = vim.fn.systemlist(cmd)
    vim.notify(table.concat(output, '\n'), vim.log.levels.INFO, { title = 'Git Blame' })
end, { desc = '[G]it [B]lame current line' })

-- Copy relative file path
vim.keymap.set('n', '<M-r>', function()
    local relpath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':.')
    vim.fn.setreg('+', relpath)
    vim.notify('Copied relative path: ' .. relpath, vim.log.levels.INFO)
end, { desc = 'Copy relative path to clipboard' })

-- ===========================
-- ✨ Autocommands
-- ===========================
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight on yank',
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})

-- ===========================
-- 🔌 Plugin Management
-- ===========================
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local repo = 'https://github.com/folke/lazy.nvim.git'
    local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', repo, lazypath }
    if vim.v.shell_error ~= 0 then
        error('Error cloning lazy.nvim:\n' .. out)
    end
end
vim.opt.rtp:prepend(lazypath)

-- ======================================
-- 🌙 Lazy.nvim Plugin Setup
-- ======================================
require('lazy').setup({

    -- 🧩 Utilities
    'NMAC427/guess-indent.nvim',
    {
        'tpope/vim-sleuth',
        lazy = false,
    },
    {
        'numToStr/Comment.nvim',
    },

    -- ✨ UI & Theme
    {
        'folke/tokyonight.nvim',
        priority = 1000,
        config = function()
            require('tokyonight').setup {
                styles = { comments = { italic = false } },
            }
            vim.cmd.colorscheme 'tokyonight-night'
            vim.api.nvim_set_hl(0, 'Visual', { bg = '#3d59a1', fg = 'NONE' })
        end,
    },

    -- 📂 File Explorer
    {
        'stevearc/oil.nvim',
        opts = {
            view_options = {
                show_hidden = true,
                is_always_hidden = function(name, _)
                    return name == 'node_modules' or name == '.git' or name == 'obj' or name == 'bin'
                end,
            },
            keymaps = { ['<C-p>'] = false },
        },
        dependencies = { { 'nvim-mini/mini.icons', opts = {} } },
        lazy = false,
    },
    -- 🔍 Telescope
    {
        'nvim-telescope/telescope.nvim',
        event = 'VimEnter',
        dependencies = {
            'nvim-lua/plenary.nvim',
            { 'nvim-telescope/telescope-ui-select.nvim' },
            { 'nvim-tree/nvim-web-devicons', enabled = true },
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                build = 'make',
                cond = function()
                    return vim.fn.executable 'make' == 1
                end,
            },
        },
        config = function()
            local telescope = require 'telescope'
            local builtin = require 'telescope.builtin'
            telescope.setup {
                extensions = { ['ui-select'] = require('telescope.themes').get_dropdown() },
            }
            pcall(telescope.load_extension, 'fzf')
            pcall(telescope.load_extension, 'ui-select')

            -- Keymaps
            vim.keymap.set('n', '<leader>sg', function()
                builtin.live_grep {
                    additional_args = function()
                        return { '--hidden', '--glob', '!.git/*', '--glob', '!node_modules/*' }
                    end,
                }
            end, { desc = '[S]earch by [G]rep (hidden files included)' })

            vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
            vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch recent files' })
            vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = 'Find existing buffers' })
            vim.keymap.set('n', '<leader>rs', builtin.resume, { desc = '[R]esume [S]earch' })
            vim.keymap.set('n', '<leader>sf', function()
                builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false })
            end, { desc = 'Fuzzy search in current buffer' })

            vim.keymap.set('n', '<C-p>', function()
                local ok = pcall(builtin.git_files, { show_untracked = true })
                if not ok then
                    builtin.find_files()
                end
            end, { desc = 'Search Git files (Ctrl+P)' })
        end,
    },

    -- 🔧 Dev Tools
    {
        'folke/lazydev.nvim',
        ft = 'lua',
        opts = {
            library = {
                { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
            },
        },
    },
    {
        'seblyng/roslyn.nvim',
        opts = {},
    },

    -- 🧠 LSP + Completion
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            { 'mason-org/mason.nvim', opts = {} },
            'mason-org/mason-lspconfig.nvim',
            'WhoIsSethDaniel/mason-tool-installer.nvim',
            { 'j-hui/fidget.nvim', opts = {} },
            'saghen/blink.cmp',
        },
        config = function()
            -- diagnostics
            vim.diagnostic.config {
                severity_sort = true,
                float = { border = 'rounded', source = 'if_many' },
                underline = { severity = vim.diagnostic.severity.ERROR },
                signs = vim.g.have_nerd_font and {
                    text = {
                        [vim.diagnostic.severity.ERROR] = '󰅚 ',
                        [vim.diagnostic.severity.WARN] = '󰀪 ',
                        [vim.diagnostic.severity.INFO] = '󰋽 ',
                        [vim.diagnostic.severity.HINT] = '󰌶 ',
                    },
                } or {},
                virtual_text = {
                    source = 'if_many',
                    spacing = 2,
                    format = function(d)
                        return d.message
                    end,
                },
            }

            local capabilities = require('blink.cmp').get_lsp_capabilities()
            local servers = {
                lua_ls = {
                    settings = {
                        Lua = {
                            completion = { callSnippet = 'Replace' },
                            diagnostics = { disable = { 'missing-fields' } },
                        },
                    },
                },
                ts_ls = {
                    settings = {
                        typescript = { organizeImports = { enable = true } },
                        javascript = { organizeImports = { enable = true } },
                    },
                },
            }

            local ensure_installed = vim.tbl_keys(servers or {})
            vim.list_extend(ensure_installed, { 'stylua', 'prettierd', 'csharp-language-server', 'csharp_ls' })
            require('mason-tool-installer').setup { ensure_installed = ensure_installed }

            require('mason-lspconfig').setup {
                handlers = {
                    function(server_name)
                        local server = servers[server_name] or {}
                        server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
                        require('lspconfig')[server_name].setup(server)
                    end,
                },
            }
        end,
    },

    {
        'pmizio/typescript-tools.nvim',
        dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
    },

    -- 🧹 Formatting
    {
        'stevearc/conform.nvim',
        event = { 'BufWritePre' },
        keys = {
            {
                '<leader>f',
                function()
                    require('conform').format { async = true, lsp_format = 'fallback' }
                end,
                desc = '[F]ormat buffer',
            },
        },
        opts = {
            notify_on_error = false,
            format_on_save = function(bufnr)
                return { timeout_ms = 5000, lsp_format = 'fallback' }
            end,
            formatters_by_ft = {
                lua = { 'stylua' },
                javascript = { 'prettierd', 'prettier', stop_after_first = true },
                typescript = { 'prettierd', 'prettier', stop_after_first = true },
                javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
                typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
                json = { 'prettierd', 'prettier', stop_after_first = true },
                cs = { 'csharpier' },
            },
        },
    },

    -- 💡 Completion (Blink + LuaSnip)
    {
        'saghen/blink.cmp',
        event = 'VimEnter',
        version = '1.*',
        dependencies = {
            {
                'L3MON4D3/LuaSnip',
                version = '2.*',
                build = (function()
                    if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
                        return
                    end
                    return 'make install_jsregexp'
                end)(),
                opts = {},
            },
            'folke/lazydev.nvim',
        },
        opts = {
            keymap = {
                ['<CR>'] = { 'select_and_accept', 'fallback' },
                ['<C-k>'] = { 'select_prev', 'fallback' },
                ['<C-j>'] = { 'select_next', 'fallback_to_mappings' },
            },
            appearance = { nerd_font_variant = 'mono' },
            completion = { documentation = { auto_show = false, auto_show_delay_ms = 500 } },
            sources = {
                default = { 'lsp', 'path', 'snippets', 'lazydev' },
                providers = {
                    lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
                },
            },
            snippets = { preset = 'luasnip' },
            fuzzy = { implementation = 'lua' },
            signature = { enabled = true },
        },
    },

    -- 🧾 Treesitter
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        main = 'nvim-treesitter.configs',
        opts = {
            ensure_installed = { 'lua', 'typescript', 'tsx' },
            auto_install = true,
            highlight = { enable = true },
            indent = { enable = true },
        },
    },
    { 'nvim-treesitter/nvim-treesitter-context' },

    -- 🔖 Grapple (File tagging)
    {
        'cbochs/grapple.nvim',
        opts = {
            scope = 'git',
            win_opts = { width = 120 },
        },
        event = { 'BufReadPost', 'BufNewFile' },
        cmd = 'Grapple',
        keys = {
            { '<leader>a', '<cmd>Grapple toggle<cr>', desc = 'Grapple toggle tag' },
            { '<C-e>', '<cmd>Grapple toggle_tags<cr>', desc = 'Grapple tags window' },
            { '<M-1>', '<cmd>Grapple select index=1<CR>' },
            { '<M-2>', '<cmd>Grapple select index=2<CR>' },
            { '<M-3>', '<cmd>Grapple select index=3<CR>' },
            { '<M-4>', '<cmd>Grapple select index=4<CR>' },
            { '<M-5>', '<cmd>Grapple select index=5<CR>' },
        },
    },

    -- 🪟 Git Integration
    {
        'lewis6991/gitsigns.nvim',
        opts = {
            signs = {
                add = { text = '+' },
                change = { text = '~' },
                delete = { text = '_' },
                topdelete = { text = '‾' },
                changedelete = { text = '~' },
            },
        },
    },
    {
        'kdheepak/lazygit.nvim',
        cmd = { 'LazyGit', 'LazyGitCurrentFile', 'LazyGitFilter', 'LazyGitFilterCurrentFile' },
        dependencies = { 'nvim-lua/plenary.nvim' },
        keys = { { '<leader>g', '<cmd>LazyGit<cr>', desc = 'LazyGit' } },
    },
    {
        'NeogitOrg/neogit',
        dependencies = {
            'nvim-lua/plenary.nvim', -- required
            'sindrets/diffview.nvim', -- optional - Diff integration

            -- Only one of these is needed.
            'nvim-telescope/telescope.nvim', -- optional
        },
    },
    -- 🤖 Copilot
    {
        'github/copilot.vim',
        event = 'VimEnter',
    },

    {
        'CopilotC-Nvim/CopilotChat.nvim',
        dependencies = {
            { 'nvim-lua/plenary.nvim', branch = 'master' },
        },
        build = 'make tiktoken',
        opts = {
            model = 'gpt-5-codex',
        },
        keys = {
            { '<leader>cc', '<cmd>CopilotChat<cr>', mode = 'n', desc = 'Open Copilot Chat' },
            { '<leader>ce', '<cmd>CopilotChatExplain<cr>', mode = 'v', desc = 'Explain code in Copilot Chat' },
            { '<leader>cg', '<cmd>CopilotCommit<cr>', mode = 'n', desc = 'Commit code suggestion from Copilot' },
        },
    },
    -- 🧱 Mini plugins
    {
        'nvim-mini/mini.nvim',

        event = 'VimEnter',
        config = function()
            require('mini.ai').setup()
            require('mini.surround').setup()
            require('mini.pairs').setup()
            require('mini.bracketed').setup()
            require('mini.statusline').setup()
        end,
    },
}, {
    ui = {
        icons = {} or {
            cmd = '⌘',
            config = '🛠',
            event = '📅',
            ft = '📂',
            init = '⚙',
            keys = '🗝',
            plugin = '🔌',
            runtime = '💻',
            require = '🌙',
            source = '📄',
            start = '🚀',
            task = '📌',
            lazy = '💤 ',
        },
    },
})
