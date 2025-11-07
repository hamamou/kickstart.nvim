vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.opt.termguicolors = true
vim.g.have_nerd_font = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.schedule(function()
    vim.o.clipboard = 'unnamedplus'
end)
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.smartindent = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 500
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 16
vim.o.confirm = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<C-s>', '<cmd>w<CR>', { desc = 'Save file' })
vim.keymap.set('i', '<C-s>', '<Esc><cmd>w<CR>', { desc = 'Save file' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<C-j>', '<cmd>cnext<CR>', { desc = 'Go to next quickfix' })
vim.keymap.set('n', '<C-k>', '<cmd>cprev<CR>', { desc = 'Go to previous quickfix' })
vim.keymap.set('n', '<C-w>v', '<cmd>vsplit<CR>')
vim.keymap.set('n', '<C-w>s', '<cmd>split<CR>')
vim.keymap.set('v', '>', '>gv', { desc = 'Indent and keep selection' })
vim.keymap.set('v', '<', '<gv', { desc = 'Unindent and keep selection' })

vim.keymap.set('n', '<leader>gf', function()
    vim.cmd "cexpr systemlist('git diff --name-only')"
    vim.cmd 'copen'
end, { desc = 'Show git changed files in quickfix window' })

vim.keymap.set('n', '<C-b>', function()
    print 'Building...'
    local output = vim.fn.systemlist 'dotnet build -nologo -consoleloggerparameters:NoSummary'
    local exit_code = vim.v.shell_error

    local errors = {}
    for _, line in ipairs(output) do
        if line:match 'error' then
            table.insert(errors, line)
        end
    end

    vim.fn.setqflist({}, 'r', {
        title = 'dotnet build errors',
        lines = errors,
    })

    if #errors > 0 or exit_code ~= 0 then
        vim.cmd 'copen'
    else
        vim.cmd 'cclose'
        print '✅ Build succeeded'
    end
end, { desc = 'Build .NET project' })

vim.keymap.set('n', '<C-q>', '<cmd>copen<CR>', { desc = 'Open quickfix list' })
vim.opt.shell = 'powershell'
vim.opt.shellcmdflag = '-NoProfile -ExecutionPolicy RemoteSigned -Command'
vim.opt.shellquote = '"'
vim.opt.shellxquote = ''

vim.keymap.set('n', '<leader>gb', function()
    local relpath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':.')

    local line_num = vim.fn.line '.'

    local blame_cmd = string.format('git log -1 -L %d,%d:%s --no-patch --format="%%an | %%s | %%cr"', line_num, line_num, relpath)
    local output = vim.fn.systemlist(blame_cmd)
    vim.notify(table.concat(output, '\n'), vim.log.levels.INFO, { title = 'Git Blame' })
end, { desc = '[G]it [B]lame current line' })

vim.keymap.set('n', '<M-r>', function()
    local relpath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':.')
    vim.fn.setreg('+', relpath)
    vim.notify('Copied relative path to clipboard: ' .. relpath, vim.log.levels.INFO)
end, { desc = 'Copy relative path of current file to clipboard' })

vim.g.dotnet_errors_only = true
vim.g.dotnet_show_project_file = false
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
    if vim.v.shell_error ~= 0 then
        error('Error cloning lazy.nvim:\n' .. out)
    end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

require('lazy').setup({
    'NMAC427/guess-indent.nvim',
    {
        'github/copilot.vim',
        event = 'VimEnter',
    },
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
        'nvim-telescope/telescope.nvim',
        event = 'VimEnter',
        dependencies = {
            'nvim-lua/plenary.nvim',
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                build = 'make',
                cond = function()
                    return vim.fn.executable 'make' == 1
                end,
            },
            { 'nvim-telescope/telescope-ui-select.nvim' },

            { 'nvim-tree/nvim-web-devicons', enabled = true },
        },
        config = function()
            require('telescope').setup {
                extensions = {
                    ['ui-select'] = {
                        require('telescope.themes').get_dropdown(),
                    },
                },
            }

            pcall(require('telescope').load_extension, 'fzf')
            pcall(require('telescope').load_extension, 'ui-select')

            local builtin = require 'telescope.builtin'
            vim.keymap.set('n', '<leader>sg', function()
                require('telescope.builtin').live_grep {
                    additional_args = function(_)
                        return {
                            '--hidden',
                            '--glob',
                            '!.git/*',
                            '--glob',
                            '!node_modules/*',
                        }
                    end,
                }
            end, { desc = '[S]earch by [G]rep (including hidden files, excluding .git & node_modules)' })
            vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
            vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
            vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
            vim.keymap.set('n', '<leader>rs', builtin.resume, { desc = '[R]esume [S]earch' })
            vim.keymap.set('n', '<leader>sf', function()
                builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                    winblend = 10,
                    previewer = false,
                })
            end, { desc = '[/] Fuzzily search in current buffer' })

            vim.keymap.set('n', '<C-p>', function()
                local ok = pcall(builtin.git_files, { show_untracked = true })
                if not ok then
                    builtin.find_files()
                end
            end, { desc = 'Search [Git] files (Cmd+P)' })
        end,
    },
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
        ---@module 'roslyn.config'
        ---@type RoslynNvimConfig
        opts = {},
    },
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
            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
                callback = function(event)
                    local map = function(keys, func, desc, mode)
                        mode = mode or 'n'
                        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
                    end

                    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
                    map('ga', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
                    map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
                    map('gi', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
                    map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
                    map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

                    ---@param client vim.lsp.Client
                    ---@param method vim.lsp.protocol.Method
                    ---@param bufnr? integer
                    ---@return boolean
                    local function client_supports_method(client, method, bufnr)
                        if vim.fn.has 'nvim-0.11' == 1 then
                            return client:supports_method(method, bufnr)
                        else
                            return client.supports_method(method, { bufnr = bufnr })
                        end
                    end

                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
                        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
                        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.document_highlight,
                        })

                        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.clear_references,
                        })

                        vim.api.nvim_create_autocmd('LspDetach', {
                            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
                            callback = function(event2)
                                vim.lsp.buf.clear_references()
                                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
                            end,
                        })
                    end
                end,
            })

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
                    format = function(diagnostic)
                        local diagnostic_message = {
                            [vim.diagnostic.severity.ERROR] = diagnostic.message,
                            [vim.diagnostic.severity.WARN] = diagnostic.message,
                            [vim.diagnostic.severity.INFO] = diagnostic.message,
                            [vim.diagnostic.severity.HINT] = diagnostic.message,
                        }
                        return diagnostic_message[diagnostic.severity]
                    end,
                },
            }
            local capabilities = require('blink.cmp').get_lsp_capabilities()
            local servers = {

                lua_ls = {
                    settings = {
                        Lua = {
                            completion = {
                                callSnippet = 'Replace',
                            },
                            diagnostics = { disable = { 'missing-fields' } },
                        },
                    },
                },
                ts_ls = {
                    settings = {
                        typescript = {
                            organizeImports = {
                                enable = true,
                            },
                        },
                        javascript = {
                            organizeImports = {
                                enable = true,
                            },
                        },
                    },
                },
            }

            local ensure_installed = vim.tbl_keys(servers or {})
            vim.list_extend(ensure_installed, {
                'stylua',
                'prettierd',
                'csharp-language-server',
                'csharp_ls',
            })
            require('mason-tool-installer').setup { ensure_installed = ensure_installed }

            require('mason-lspconfig').setup {
                ensure_installed = {},
                automatic_installation = false,
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
    {
        'stevearc/conform.nvim',
        event = { 'BufWritePre' },
        cmd = { 'ConformInfo' },
        keys = {
            {
                '<leader>f',
                function()
                    require('conform').format { async = true, lsp_format = 'fallback' }
                end,
                mode = '',
                desc = '[F]ormat buffer',
            },
        },
        opts = {
            notify_on_error = false,
            format_on_save = function(bufnr)
                local disable_filetypes = { c = true, cpp = true }
                if disable_filetypes[vim.bo[bufnr].filetype] then
                    return nil
                else
                    return {
                        timeout_ms = 5000,
                        lsp_format = 'fallback',
                    }
                end
            end,
            formatters_by_ft = {
                lua = { 'stylua' },
                javascript = { 'prettierd', 'prettier', stop_after_first = true },
                typescript = { 'prettierd', 'prettier', stop_after_first = true },
                javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
                typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
                cs = { 'csharpier' },
            },
        },
    },
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
                dependencies = {},
                opts = {},
            },
            'folke/lazydev.nvim',
        },
        --- @module 'blink.cmp'
        --- @type blink.cmp.Config
        opts = {
            keymap = {
                ['<CR>'] = { 'select_and_accept', 'fallback' },
                ['<C-k>'] = { 'select_prev', 'fallback' },
                ['<C-j>'] = { 'select_next', 'fallback_to_mappings' },
            },

            appearance = {
                nerd_font_variant = 'mono',
            },

            completion = {
                documentation = { auto_show = false, auto_show_delay_ms = 500 },
            },

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
    {
        'folke/tokyonight.nvim',
        priority = 1000,
        config = function()
            ---@diagnostic disable-next-line: missing-fields
            require('tokyonight').setup {
                styles = {
                    comments = { italic = false },
                },
            }

            vim.cmd.colorscheme 'tokyonight-night'
            vim.api.nvim_set_hl(0, 'Visual', { bg = '#3d59a1', fg = 'NONE' })
        end,
    },
    {
        'numToStr/Comment.nvim',
    },
    {
        'nvim-mini/mini.nvim',
        event = 'VeryLazy',
        config = function()
            require('mini.ai').setup()
            require('mini.surround').setup()
            require('mini.pairs').setup()
            require('mini.bracketed').setup()
            require('mini.files').setup {
                content = {
                    filter = function(entry)
                        local exclude = { 'bin', 'Bin', 'obj', 'node_modules', '.vs', '.git', '.githook' }
                        for _, name in ipairs(exclude) do
                            if entry.name == name then
                                return false
                            end
                        end
                        return true
                    end,
                },
                windows = {
                    width_preview = 100,
                },
                options = {
                    use_as_default_explorer = true,
                },
            }
            require('mini.indentscope').setup {
                symbol = '|',
            }
            require('mini.cursorword').setup()
            require('mini.statusline').setup {}

            vim.keymap.set('n', '<leader>e', function()
                local buf_name = vim.api.nvim_buf_get_name(0)
                local path = vim.fn.filereadable(buf_name) == 1 and buf_name or vim.fn.getcwd()
                MiniFiles.open(path)
                MiniFiles.reveal_cwd()
            end, { desc = 'Open Mini Files' })
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        main = 'nvim-treesitter.configs',
        opts = {
            ensure_installed = {
                'lua',
                'typescript',
                'tsx',
            },
            auto_install = true,
            highlight = {
                enable = true,
            },
            indent = { enable = true },
        },
    },
    {
        'cbochs/grapple.nvim',
        opts = {
            scope = 'git',
            win_opts = {
                width = 120,
            },
        },
        event = { 'BufReadPost', 'BufNewFile' },
        cmd = 'Grapple',
        keys = {
            { '<leader>a', '<cmd>Grapple toggle<cr>', desc = 'Grapple toggle tag' },
            { '<C-e>', '<cmd>Grapple toggle_tags<cr>', desc = 'Grapple open tags window' },
            { '<M-1>', '<cmd>Grapple select index=1<CR>' },
            { '<M-2>', '<cmd>Grapple select index=2<CR>' },
            { '<M-3>', '<cmd>Grapple select index=3<CR>' },
            { '<M-4>', '<cmd>Grapple select index=4<CR>' },
            { '<M-5>', '<cmd>Grapple select index=5<CR>' },
        },
    },
    {
        'nvim-treesitter/nvim-treesitter-context',
    },
    {
        'kdheepak/lazygit.nvim',
        lazy = true,
        cmd = {
            'LazyGit',
            'LazyGitConfig',
            'LazyGitCurrentFile',
            'LazyGitFilter',
            'LazyGitFilterCurrentFile',
        },
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
        keys = {
            { '<leader>g', '<cmd>LazyGit<cr>', desc = 'LazyGit' },
        },
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
