vim.keymap.set("n", "<leader>pv", function() vim.cmd(":Ex") end)

-- Rebind Esc to a reachable place.
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("c", "jk", "<Esc>")

-- Move highlighted lines.
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Make line append not move cursor.
vim.keymap.set("n", "J", "mzJ`z")

-- Make fast jump keep cursor in the middle.
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Make leader p paste over highlighted word.
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Make leader y yank to clipboard.
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set("n", "Q", "<nop>")

-- Format buffer.
vim.keymap.set("n", "<leader>f", function()
    vim.lsp.buf.format()
end)

-- Quickfix navigation.
vim.keymap.set("n", "<C-Up>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-Down>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

