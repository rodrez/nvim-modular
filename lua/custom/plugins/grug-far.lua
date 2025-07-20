return {
  "MagicDuck/grug-far.nvim",
  opts = { headerMaxWidth = 80 },
  cmd = { "GrugFar" },
  keys = {
    {
      "<leader>sG",
      function()
        local grug = require("gruv-far")
        local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
        grug.open({
          transient = true,
          prefills = {
            filesFilter = ext and ext ~= "" and "*." .. ext or nil,
          },
        })
      end,
      mode = { "n", "v" },
      desc = "Search and Replace",
    },
  }
}
