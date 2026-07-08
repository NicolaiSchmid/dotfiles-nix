return {
  -- Smooth scrolling
  {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    opts = {
      mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "zt", "zz", "zb" },
    },
  },

  -- Git blame
  {
    "f-person/git-blame.nvim",
    event = "VeryLazy",
    opts = {
      enabled = true,
      date_format = "%Y-%m-%d",
      message_when_not_committed = "Not committed yet",
      virtual_text_column = 80,
    },
  },

  -- .env file support
  {
    "ellisonleao/dotenv.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- Show dotfiles in neo-tree
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
    },
  },

  -- Show dotfiles in snacks file picker (leader leader)
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = {
            hidden = true,
          },
        },
      },
    },
  },
}
