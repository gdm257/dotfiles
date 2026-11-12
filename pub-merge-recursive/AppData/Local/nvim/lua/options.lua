require "nvchad.options"

-- add yours here!

local opt = vim.opt

-- Cwd rc file
-- .nvim.lua
-- .nvimrc
-- .exrc
opt.exrc = true

-- GUI fonts
opt.guifont = {
  "JetBrainsMono Nerd Font",
  "LXGW WenKai Screen R",
}

-- Stacked jumplist
-- make `CTRL-o` to be intuitive
opt.jumpoptions = "stack"
