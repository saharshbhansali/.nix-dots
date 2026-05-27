return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            local ensure_installed = {
                black = true,
                codelldb = true,
                gitui = true,
                gofumpt = true,
                goimports = true,
                gopls = true,
                hadolint = true,
                jdtls = true,
                -- ["lua-language-server"] = true,
                marksman = true,
                -- ["nil"] = true,
                -- ["nil_ls"] = true,
                ruff = true,
                shellcheck = true,
                shfmt = true,
                sqlfluff = true,
                stylua = true,
                taplo = true,
                texlab = true,
                zls = true,
            }

            -- 1. Explicitly inject the nixd configuration into opts.servers
            opts.servers = opts.servers or {}
            opts.servers.nixd = {
                cmd = { "nixd" },
                settings = {
                    nixd = {
                        nixpkgs = {
                            expr = "import <nixpkgs> { }",
                        },
                        formatting = {
                          command = "alejandra",
                        },
                        -- Optional: Add your flake options path here if you use flakes
                        -- options = {
                        --   nixos = { expr = '(builtins.getFlake "/path/to/flake").nixosConfigurations.myhostname.options' }
                        -- }
                    },
                },
            }

            for server, server_opts in pairs(opts.servers) do
                if type(server_opts) == "table" and not ensure_installed[server] then
                    server_opts.mason = false
                end
            end

            return opts
        end,
    },
    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = { "pyrefly", "jupytext" }
        end,
    },
}
