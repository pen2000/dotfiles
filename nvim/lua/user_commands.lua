vim.keymap.set('n', '<space>q', function()
  if not pcall(vim.cmd.tabclose) then
    vim.cmd.quit()
  end
end, { desc = 'Quit current tab or window' })
