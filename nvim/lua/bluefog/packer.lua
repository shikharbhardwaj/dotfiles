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

	-- Treesitter
	-- Pinned to the `master` branch: `main` is a full API rewrite that
	-- requires Neovim 0.12 (nightly); `master` is still officially
	-- maintained for backward compatibility with the 0.11 stable release.
	use { 'nvim-treesitter/nvim-treesitter', branch = 'master', run = ':TSUpdate' }

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

	-- LSP support, via Neovim's native vim.lsp.config/vim.lsp.enable (0.11+)
	use { 'neovim/nvim-lspconfig' }
	use { 'mason-org/mason.nvim' }
	use { 'mason-org/mason-lspconfig.nvim' }

	-- Autocompletion
	use { 'hrsh7th/nvim-cmp' }
	use { 'hrsh7th/cmp-buffer' }
	use { 'hrsh7th/cmp-path' }
	use { 'saadparwaiz1/cmp_luasnip' }
	use { 'hrsh7th/cmp-nvim-lsp' }
	use { 'hrsh7th/cmp-nvim-lua' }

	-- Snippets
	use { 'L3MON4D3/LuaSnip' }
	use { 'rafamadriz/friendly-snippets' }

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

