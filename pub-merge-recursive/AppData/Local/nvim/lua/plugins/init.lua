return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  { "wakatime/vim-wakatime" },

  {
    "loctvl842/monokai-pro.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      filter = "classic",
    },
    config = function(_, opts)
      require("monokai-pro").setup(opts)
      vim.cmd.colorscheme "monokai-pro"
    end,
  },

  {
    "mrjones2014/legendary.nvim",
    version = "v2.13.12",
    lazy = true,
    keys = {
      { "sK", desc = "Legendary Keymaps" },
      { "sp", desc = "Legendary Commands" },
    },
    opts = {
      include_builtin = true,
      include_legendary_cmds = true,
      extensions = {
        lazy_nvim = true,
        which_key = {
          auto_register = true,
          do_binding = true,
        },
      },
    },
  },

  -- no LSP
  -- {
  -- 	"neovim/nvim-lspconfig",
  -- 	config = function()
  -- 		require "configs.lspconfig"
  -- 	end,
  -- },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
}
