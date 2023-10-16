# expand.nvim
a plugin that allows u to quickly expand statements
# demo 
```
| is the cursor
in c 
if (true|)  C-Space

if (true){
    |
}

typedef struct foo |

typedef struct foo {
    |
};

in lua
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
```
'.*(.*)',{'{',          '}'},
regex   ,{openning pair,closing pair}
string    string        string
function
```
note the pairs can be keys and the regex is vim `Pattern`
the pattern is matched against the current line
the plugin makes sure 'magic' is set while checking pairs

alternatively you can use a function to evaluate wether to expand the pair or not
which returns true if the pair should be chosen and false or nil(nothing) otherwise

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
         -- if we are expaning on an unnamed function might aswell add the pairs
         { 'function\\s*$',                     { '()', 'end' } },
         { 'function',                     { '', 'end' } },
         { 'if',                           { ' then', 'end' } },
         -- regex for a lua variable
         { '^\\s*\\w\\+\\s*\\w*\\s*=\\s*', { '{', '}' } },
         { 'this is not checked',                      { ' do', 'end' } },
      },
      sh = {
         { 'elif',    { ' then', '' } },
         { 'if',      { ' then', 'if' } },
         { 'case',    { '', 'esac' } },
         { '', { ' do', 'done' } },
      },
      bash = {
         { 'elif',    { ' then', '' } },
         { 'if',      { ' then', 'if' } },
         { 'case',    { '', 'esac' } },
         { '', { ' do', 'done' } },
      },
      zsh = {
         { 'elif',    { ' then', '' } },
         { 'if',      { ' then', 'if' } },
         { 'case',    { '', 'esac' } },
         { '', { ' do', 'done' } },
      },
      c = {
         { '.*(.*)',  { '{', '}' } },
         { '', { '{', '};' } },
      },
      cpp = {
         { '.*(.*)',  { '{', '}' } },
         { '', { '{', '};' } },
      },
   },
   hotkey = '<C-Space>',
})
```
## plans
add a treesitter check to auto add comas in for lua tables inside lua tables
allow the functions to return pairs
