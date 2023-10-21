# expand.nvim
a plugin that allows u to quickly expand statements
# demo 
```c
// | is the cursor
// in c 
if (true|)  C-Space

if (true){
    |
}

typedef struct foo |

typedef struct foo {
    |
};
```
```lua
-- in lua
if something| C-Space

if something then
   |
end

local myvar = | C-space

local myvar = {
    |
}
```
## installation
packer
```lua
use {
    "Sam-programs/expand.nvim",
    requires = { 'Sam-Programs/indent.nvim' }, 
    config = function() require("expand").setup {} end
}
```
vim-plug
```vim
Plug 'Sam-Programs/expand.nvim'
Plug 'Sam-Programs/indent.nvim'

lua << EOF
require("expand").setup {}
EOF
```
## config
adding custom pairs for other languages is simple 
the syntax for the table is
```lua
'.*(.*)',{'{',          '}'},
regex   ,{openning pair,closing pair}
string    string        string
function
```
note the pairs can be keys and the regex is vim `Pattern`
the pattern is matched against the current line
the plugin makes sure 'magic' is set while checking pairs

alternatively you can use a function to evaluate wether to choose the pair or not
which returns true if the pair should be chosen and false or nil(nothing) otherwise

or a function that returns two strings which are the openning pair and closing pair and nil if we shouldn't choose it's pair
```lua
function()
   if something then
      return '{','},'
   end
   -- lua automatically returns nil here
end
```

the table for languages is like a fallback table
```lua
-- this is checked first 
{ 'function\\s*$',                     { '()', 'end' } },
-- then this
{ 'function',                     { '', 'end' } },
```
the final item in the list is used as a fallback if all other matches fail (doesn't get checked)

and finally
if there is no custom pair(s) for a filetype the plugin defaults to {}
## default setup
```lua
require('expand').setup({
   filetypes = {
      lua = {
         -- if we are expanding on an unnamed function might aswell add the pairs
         { 'function\\s*$',                { '()', 'end' } },
         { 'function',                     { '', 'end' } },
         { 'if',                           { ' then', 'end' } },
         -- regex for a lua variable
         { '^\\s*\\w\\+\\s*\\w*\\s*=\\s*$', { '{', '}' } },
         { '',                             { ' do', 'end' } },
      },
      sh = {
         { 'elif', { ' ;then', '' } },
         { 'if',   { ' ;then', 'if' } },
         { 'case', { '', 'esac' } },
         { 'while',     { ' do', 'done' } },
         { 'for',     { ' do', 'done' } },
         { '',     { '{', '}' } },
      },
      bash = {
         { 'elif', { ' ;then', '' } },
         { 'if',   { ' ;then', 'if' } },
         { 'case', { '', 'esac' } },
         { 'while',     { ' do', 'done' } },
         { 'for',     { ' do', 'done' } },
         { '',     { '{', '}' } },
      },
      zsh = {
         { 'elif', { ' then', '' } },
         { 'if',   { ' then', 'if' } },
         { 'case', { '', 'esac' } },
         { 'while',     { ' do', 'done' } },
         { 'for',     { ' do', 'done' } },
         { '',     { '{', '}' } },
      },
      c = {
         { '.*(.*)', { '{', '}' } },
         { '',       { '{', '};' } },
      },
      cpp = {
         { '.*(.*)', { '{', '}' } },
         { '',       { '{', '};' } },
      },
   },
   hotkey = '<C-Space>',
})
```
## plans
add a treesitter check to auto add comas in for lua tables inside lua tables  
## done
allow the functions to return pairs   
add tests 
