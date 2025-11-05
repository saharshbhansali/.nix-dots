return {
    -- Noice plugin
    {
        'folke/noice.nvim',
        optional = true,
        opts = {
            presets = { inc_rename = true },
        },
    },

    -- Trouble plugin
    {
        'folke/trouble.nvim',
        cmd = { 'Trouble' },
        opts = {
            modes = {
                lsp = {
                    win = { position = 'right' },
                },
            },
        },
    },

    -- -- lualine plugin
    -- {
    --     'nvim-lualine/lualine.nvim',
    --     optional = true,
    --     event = 'VeryLazy',
    --     opts = function(_, opts)
    --         if LazyVim.has_extra 'ai.sidekick' then
    --             return
    --         end
    --         table.insert(
    --             opts.sections.lualine_x,
    --             2,
    --             LazyVim.lualine.status(LazyVim.config.icons.kinds.Copilot, function()
    --                 local clients = vim.lsp.get_clients { name = 'copilot', bufnr = 0 }
    --                 return #clients > 0 and status[clients[1].id] or nil
    --             end)
    --         )
    --     end,
    -- },

    -- Treesitter plugin
    {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate', -- Ensure parsers are updated
        config = function()
            require('nvim-treesitter.configs').setup {
                ensure_installed = {}, -- Disabled
                indent = { enable = true }, ---@type lazyvim.TSFeat
                highlight = { enable = true }, ---@type lazyvim.TSFeat
                folds = { enable = true }, ---@type lazyvim.TSFeat
            }
        end,
    },
}
