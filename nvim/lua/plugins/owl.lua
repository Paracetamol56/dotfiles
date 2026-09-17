return {
	"JohnAng/owl.nvim",
	build = function()
		local sep = package.config:sub(1, 1)
		if sep == "\\" then
			vim.fn.system({ "powershell", "-ExecutionPolicy", "Bypass", "-File", "scripts/postinstall.ps1" })
		else
			vim.fn.system({ "bash", "scripts/postinstall.sh" })
		end
	end,
	ft = { "markdown", "md", "quarto", "rmarkdown", "tex", "latex" },
	keys = {
		{
			"<leader>op",
			function()
				require("owl").toggle()
			end,
			desc = "owl: toggle preview",
		},
	},
	opts = {
		server = { host = "127.0.0.1", port = 0, node = "node" },
		browser = { cmd = "auto", override = nil, new_window = false },
		markdown = {
			trigger = "live", -- 'live' | 'save'
			scroll_sync = true,
			auto_bib = true,
			bib = nil,
		},
		latex = {
			viewer = "browser", -- 'auto' | 'browser' | 'sumatra' | 'zathura' | 'skim' | 'sioyek'
			engine = "xelatex", -- 'xelatex' | 'pdflatex' | 'lualatex'
			synctex = true,
			aux_dir = ".owl-build",
			latexmk_extra = {},
		},
		diagnostics = {
			enabled = true,
			signs = true,
			virtual_text = { spacing = 2, prefix = "" },
		},
		log_level = "info", -- 'trace' | 'debug' | 'info' | 'warn' | 'error'
		auto_shutdown = true,
	},
}
