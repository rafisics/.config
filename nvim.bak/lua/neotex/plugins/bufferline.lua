return {
  "akinsho/bufferline.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  version = "*",
  config = function()
    local bufferline = require('bufferline')
    bufferline.setup({
      options = {
        mode = "buffers",
        separator_style = "slant",
        close_command = "Bdelete! %d", -- can be a string | function, see "Mouse actions"
        diagnostics = false,           -- OR: | "nvim_lsp" 
        diagnostics_update_in_insert = false,
        show_tab_indicators = false,
        show_close_icon = false,
        -- numbers = "ordinal", -- Display buffer numbers as ordinal numbers
        sort_by = 'insert_at_end', -- OR: 'insert_after_current' | 'tabs' | 'extension' | 'relative_directory' | 'directory' | 'id' |
        -- sort_by = function(buffer_a, buffer_b)
        -- --   -- add custom logic
        --   return buffer_a.ordinal < buffer_b.ordinal
        -- end,
        offsets = {
          {
            filetype = "NvimTree",
            -- text = "Explorer",
            text = function()
              return vim.fn.getcwd()
            end,
            highlight = "Directory",
            separator = "", -- use a "true" to enable the default, or set your own character
            -- padding = 1
          }
        },
        hover = {
          enabled = true,
          delay = 30,
          reveal = { 'close' }
        },
        vim.api.nvim_create_autocmd("User", {
          pattern = "AlphaReady",
          desc = "disable tabline for alpha",
          callback = function()
            vim.opt.showtabline = 0
          end,
        }),
        vim.api.nvim_create_autocmd("BufUnload", {
          buffer = 0,
          desc = "enable tabline after alpha",
          callback = function()
            vim.opt.showtabline = 2
          end,
        })
      },
    })
  end,
}
