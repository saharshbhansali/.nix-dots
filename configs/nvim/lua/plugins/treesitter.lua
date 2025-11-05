return {
    -- Noice plugin
    {
        "folke/noice.nvim",
        config = function()
            require("noice").setup({
                lsp = {
                    override = {
                        -- Optionally, override LSP progress message display
                        ["vim.lsp.util.get_progress_messages"] = true,
                    },
                },
                -- You can also add other customizations based on your needs
            })
        end,
    },

    -- Trouble plugin
    {
        "folke/trouble.nvim",
        config = function()
            require("trouble").setup({})
        end,
    },

    -- -- lualine plugin
    -- {
    --     'nvim-lualine/lualine.nvim',
    --     dependencies = { 'folke/noice.nvim' }, -- Ensure noice is available when lualine is set up
    --     config = function()
    --         require('lualine').setup {
    --             options = {
    --                 theme = 'catppuccin', -- Adjust according to your color theme
    --             },
    --             sections = {
    --                 lualine_c = { 'filename', require('noice').api.statusline }, -- Integrating Noice with Lualine
    --             },
    --         }
    --     end,
    -- },

    -- Treesitter plugin
    {
        "nvim-treesitter/nvim-treesitter",
        run = ":TSUpdate", -- Ensure parsers are updated
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {}, -- Disabled
                highlight = {
                    enable = true, -- Enable syntax highlighting
                },
                indent = {
                    enable = true, -- Enable tree-sitter based indentation
                },
            })
        end,
    },
}
