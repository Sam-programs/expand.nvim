# expand.nvim
A plugin that allows u to quickly expand statements.
## demo 
```c
// | is the cursor
// in c 
if (true|)  C-Space

if (true){
    |
}

typedef struct foo | C-Space

typedef struct foo {
    |
};

int array = | C-Space

int array = {
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

<details>
<summary>Installation</summary>

lazy
```lua
{
    "Sam-programs/expand.nvim",
    dependencies = { 'Sam-Programs/indent.nvim' },
    event = 'InsertEnter',
    opts = {

    }
}
```
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

</details>

## config
The syntax for the filetype table is:
```lua
{'.*(.*)',{'{',          '}'}}
regex   ,{Opening pair,Closing pair, {Options}}
string    string        string        

{'.*(.*)',function() 
   print("something")
end}
regex   ,function, {Options}
string   function 
function  
```
You can look at [the default configuration](#default-config) for examples.

<details>
<summary>Options</summary>

```lua
go_to_end  -- whether you should move out of pairs before adding the end pair or not
do_nothing -- useful if you you accidentally press <C-space>
endpair_new_line -- endpairs don't get a new line eg
lua_pattern -- use :h lua-patterns instead of :h Pattern
```
</details>

The pairs are unmapped keys and 'regex' is vim `Pattern` unless the lua_pattern option is true, the pattern is matched against the current line, the plugin makes sure 'magic' is set while matching pairs
'regex' can also be a function instead.

You can also use a function instead of pairs:
```lua
{ 'some pattern', function(match)
    local k = vim.keycode
    -- using a function to use both mapped and unmapped keys
    vim.api.nvim_feedkeys(k("unmapped keys"), "n", false)
    vim.api.nvim_input("mapped keys")
end }
```

The table for filetype is like a fallback table:
```lua
-- this is checked first 
{ 'function\\s*$',{ '()', 'end' } },
-- then this
{ 'function',     { '', 'end' } },
```
The final item in the list is used as a fallback if all other matches fail.

If there is no custom pair(s) for a filetype the plugin defaults to `default_rule`, there is also a `default_options` key which is used on all rules that don't have a value for an option.
```lua
config = {
    default_rule = {
        { '', { '{', '}' } },
    },
    default_options = {
        lua_pattern = true -- always use lua patterns instead of :h Pattern 
    },
}
```
You can call setup with a different key to define another mapping with different rules.
## default config
```lua
local sh_rules = {
    { 'elif',  { ' ;then', '' },   { lua_pattern = true, endpair_new_line = false } },
    { 'if',    { ' ;then', 'fi' }, { lua_pattern = true } },
    { 'case',  { '', 'esac' },     { lua_pattern = true } },
    { 'while', { ' do', 'done' },  { lua_pattern = true } },
    { 'for',   { ' do', 'done' },  { lua_pattern = true } },
    { '',      { '{', '}' } },
}
local config = {
    filetypes = {
        python = {
            { '', { ':', '' }, { endpair_new_line = false } },
        },
        lua = {
            -- regex for a lua variable
            { '%s*%w*%s*[a-zA-z.]+%s*=%s*$', { '{', '}' },       { lua_pattern = true } },
            { 'if',                           { ' then', 'end' }, { lua_pattern = true } },
            -- if we are expanding on an unnamed function might as well add the pairs
            { 'function[^(]*$',               { '()', 'end' },    { lua_pattern = true, go_to_end = false } },
            { 'function',                     { '', 'end' },      { lua_pattern = true } },
            { 'loops',                        { ' do', 'end' },   { lua_pattern = true } },
        },
        sh = sh_rules,
        bash = sh_rules,
        zsh = sh_rules,
        c = {
            { '.*(.*)',            { '{', '}' },  { lua_pattern = false } },
            { 'else',              { '{', '}' },  { lua_pattern = true } },
            -- an empty line is likely in an array
            { '^%s*$',             { '{', '},' }, { lua_pattern = true } },
            { '^%s*\\.%w+%s*=%s*', { '{', '},' }, { lua_pattern = true } },
            { 'struct',            { '{', '};' } },
        },
        cpp = {
            { '.*(.*)',            { '{', '}' },  { lua_pattern = false } },
            { 'namespace',         { '{', '}' },  { lua_pattern = true } },
            { 'else',              { '{', '}' },  { lua_pattern = true } },
            -- an empty line is likely in an array
            { '^%s*$',             { '{', '},' }, { lua_pattern = true } },
            { '^%s*\\.%w+%s*=%s*', { '{', '},' }, { lua_pattern = true } },
            { 'class',             { '{', '};' }, },
        },
    },
    default_rule = 
    { '', { '{', '}' } },
    default_options = {
        lua_pattern = false
    },
    hotkey = '<C-Space>',
}
require('expand').setup(config)
```
## plans
Add a treesitter check to auto add comas in for lua tables inside lua tables  
## testing
to test the plugin make sure u have expand setup correctly and [keymap-tester](https://github.com/Sam-programs/keymap-tester.nvim)
then cd to the tests directory and run make
```
cd tests && make
```
