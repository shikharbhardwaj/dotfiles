local lsp = require('lsp-zero')
lsp.preset('recommended')

lsp.ensure_installed({
  'cssls',
  'sumneko_lua',
  'rust_analyzer'
})

lsp.setup()
