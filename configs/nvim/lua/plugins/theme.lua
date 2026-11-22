return {
    {
        "folke/tokyonight.nvim",
        lazy = true,
        opts = {
            transparent = true,
            style = "moon",
            -- styles = {
            --     sidebars = "transparent",
            --     floats = "transparent",
            -- },
        },
    },

    {
        "catppuccin/nvim",
        lazy = false,
        -- LazyVim (priority 10000) applies the colorscheme during its own config.
        -- Catppuccin's setup() must run first, otherwise the theme is generated
        -- with default options (transparent_background = false) and the later
        -- setup() only recompiles the cache without re-applying the highlights.
        priority = 10001,
        name = "catppuccin",
        opts = {
            flavour = "mocha",
            transparent_background = true,
            -- Optional: Make floating windows (like Telescope, Neo-tree, WhichKey) transparent too
            float = {
                transparent = true,
                solid = false,
            },
            dim_inactive = {
                enabled = false, -- dims the background color of inactive window
                shade = "dark",
                percentage = 0.00, -- percentage of the shade to apply to the inactive window
            },
            -- custom_highlights = function(colors)
            --     return {
            --         NormalFloat = { bg = nil, fg = colors.text },
            --         Normal = { bg = nil , fg = colors.base },
            --     }
            -- end,
            lsp_styles = {
                underlines = {
                    errors = { "undercurl" },
                    hints = { "undercurl" },
                    warnings = { "undercurl" },
                    information = { "undercurl" },
                },
            },
            integrations = {
                aerial = true,
                alpha = true,
                bufferline = true,
                cmp = true,
                dashboard = true,
                flash = true,
                fzf = true,
                grug_far = true,
                gitsigns = true,
                headlines = true,
                illuminate = true,
                indent_blankline = { enabled = true },
                leap = true,
                lsp_trouble = true,
                mason = true,
                markdown = true,
                mini = true,
                navic = { enabled = true, custom_bg = "lualine" },
                neotest = true,
                neotree = true,
                noice = true,
                notify = true,
                semantic_tokens = true,
                snacks = true,
                telescope = true,
                treesitter = true,
                treesitter_context = true,
                which_key = true,
            },
        },
        specs = {
            {
                "akinsho/bufferline.nvim",
                optional = true,
                opts = function(_, opts)
                    if (vim.g.colors_name or ""):find("catppuccin") then
                        opts.highlights = require("catppuccin.special.bufferline").get_theme()
                    end
                end,
            },
        },
    },

    {
        "akinsho/bufferline.nvim",
        optional = true,
        opts = function(_, opts)
            if (vim.g.colors_name or ""):find("catppuccin") then
                opts.highlights = require("catppuccin.special.bufferline").get_theme()
            end
        end,
    },

    -- Configure LazyVim to load catppuccin
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "catppuccin",
        },
    },
}
