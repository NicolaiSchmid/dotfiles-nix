-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Scroll less with <C-d> and <C-u> (5 lines instead of half page)
vim.keymap.set({ "n", "v" }, "<C-d>", "5<C-d>", { desc = "Scroll down" })
vim.keymap.set({ "n", "v" }, "<C-u>", "5<C-u>", { desc = "Scroll up" })
