return {
  {
        "mason-org/mason.nvim",
        version = "^1.0.0",
        cmd = "Mason",
        keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
        build = ":MasonUpdate",
        opts_extend = { "ensure_installed" },
        opts = {
            ensure_installed = {
                "stylua",
                "shfmt",
            },
        },
    },
    { "mason-org/mason-lspconfig.nvim", version = "^1.0.0" },
}
