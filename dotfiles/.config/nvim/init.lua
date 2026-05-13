-- Remove o fundo do editor, das colunas de sinais e números
vim.cmd([[
  highlight Normal guibg=none
  highlight NonText guibg=none
  highlight NormalNC guibg=none
  highlight SignColumn guibg=none
  highlight StatusLine guibg=none
  highlight StatusLineNC guibg=none
]])
