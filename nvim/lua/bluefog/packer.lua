-- This file can be loaded by calling `lua require('plugins')` from your init.vim
-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
	-- Packer can manage itself
	use { 'wbthomason/packer.nvim' }

	use {
		'nvim-telescope/telescope.nvim', tag = '0.1.0',
		-- or                            , branch = '0.1.x',
		requires = { {'nvim-lua/plenary.nvim'} }
	}

	-- Colorschemes
	-- tokyonight.vim (https://github.com/folke/tokyonight.nvim)
	use { 'folke/tokyonight.nvim' }
	-- rose-pine
	use { 'rose-pine/neovim', as = 'rose-pine', tag = 'v1.1.0' }

	-- Tmux integration
	use({
		"aserowy/tmux.nvim",
		config = function() require("tmux").setup() end
	})

	-- Harpoon
	use { 'theprimeagen/harpoon' }

	-- Undotree
	use { 'mbbill/undotree' }

	use { 'tpope/vim-fugitive' }

    -- nvim-surround
    use({
        'kylechui/nvim-surround',
        tag = "*", -- Use for stability; omit to use `main` branch for the latest features
        config = function()
            require('nvim-surround').setup({
                -- Configuration here, or leave empty to use defaults
            })
        end
    })


    -- lazygit
    use({
        'kdheepak/lazygit.nvim',
        -- optional for floating window border decoration
        requires = {
            'nvim-lua/plenary.nvim',
        },
    })

    -- Gitsigns (gutter indication of diff)
    use {
      'lewis6991/gitsigns.nvim',
    }


    use {
      'nvim-tree/nvim-tree.lua',
      requires = {
          'nvim-tree/nvim-web-devicons'
      },
      config = function ()
        require('gitsigns').setup()
      end
    }
end)

