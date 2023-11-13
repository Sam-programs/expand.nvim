-- init.lua
-- if u are using lazy
local lazypath = vim.fn.stdpath('data') .. '/lazy/'
vim.o.rtp = 
lazypath .. 'keymap-tester.nvim' .. ',' ..
lazypath .. 'expand.nvim' .. ',' ..
lazypath .. 'indent.nvim'

-- if u don't turn off indenting you'ill have to add the extra spaces to the tests
vim.o.indentexpr = '0'
require('expand').setup{}
local ok,Test = pcall(require('keymap-tester'))
if not ok then
   print('keymap-tester.nvim is required for testing expand.nvim')
   print('https://github.com/Sam-programs/keymap-tester.nvim')
   vim.cmd('q!')
end

Test("if()<left><C-space>", "if(){\n\n}", "if statement", "cpp")
Test("if()<left><C-space>if()<left><C-space>", "if(){\nif(){\n\n}\n}", "double if statement", "cpp")

Test("struct foo<C-space>", "struct foo{\n\n};", "struct", "cpp")
Test("class foo<C-space>", "class foo{\n\n};", "class", "cpp")

Test("void foo()<left><C-space>", "void foo(){\n\n}", "function", "cpp")

-- lua
Test("if true<C-space>", "if true then\n\nend", "if statement", "lua")
Test("if true<C-space>if true<C-Space>", "if true then\nif true then\n\nend\nend", "double if statement", "lua")

Test("function foo()<C-space>", "function foo()\n\nend", "function", "lua")
Test("function foo() <C-space>", "function foo() \n\nend", "function with spaces", "lua")
Test("function<C-space>", "function()\n\nend", "empty function", "lua")
Test("function <C-space>", "function ()\n\nend", "empty function with spaces", "lua")

-- should fail
Test("functio()<C-space>", "function()\n\nend", "should fail typo", "lua")

vim.cmd('q!')
