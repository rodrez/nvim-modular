return {
  "supermaven-inc/supermaven-nvim",
  config = function()
    require("supermaven-nvim").setup({
      opts = {
        disable_inline_completion = true,
      }
    })
  end,
}
