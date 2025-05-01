-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua

---@type ChadrcConfig

local M = {}

M.base46 = {
  theme = "gruvbox",
  theme_toggle = { "gruvbox", "gruvbox_light" },
  transparency = true,
  hl_override = {
    ["Visual"] = { bg = "#787859", fg = "#D4D4D4" },
    -- ["Comment"] = { fg = "#B5B596" },
  },
}

return M
