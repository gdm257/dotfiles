return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  { "wakatime/vim-wakatime" },

  {
    "milanglacier/minuet-ai.nvim",
    event = "InsertEnter",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      provider = "openai_compatible",
      provider_options = {
        openai_compatible = {
          name = "ai-gateway",
          end_point = "http://localhost:8080/v1/chat/completions",
          model = "claude-haiku-4-5",
          api_key = "OPENAI_API_KEY",
          system = "You are a completion engine: given context with a gap, output only the text that fills or continues it.",
        },
      },
    },
  },

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
