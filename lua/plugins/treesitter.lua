return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	event = { "BufReadPost", "BufNewFile" },
	opts = {
		ensure_installed = {
			"lua", "tsx", "typescript", "javascript",
			"html", "css", "json", "markdown"
		},
		auto_install = true,
		hightlight = {
			enabled = true,
			additional_vim_regex_highlighting = false,
		},
		indent = {
			enabled = true
		},
	}
}
