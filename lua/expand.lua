local MATCH = 1
local PAIRS = 2

local default = {
   filetypes = {
      lua = {
         -- if we are expaning on an unnamed function might aswell add the pairs
         { 'function\\s*$',                { '()', 'end' } },
         { 'function',                     { '', 'end' } },
         { 'if',                           { ' then', 'end' } },
         -- regex for a lua variable
         { '^\\s*\\w\\+\\s*\\w*\\s*=\\s*', { '{', '}' } },
         { '',                             { ' do', 'end' } },
      },
      sh = {
         { 'elif', { ' then', '' } },
         { 'if',   { ' then', 'if' } },
         { 'case', { '', 'esac' } },
         { '',     { ' do', 'done' } },
      },
      bash = {
         { 'elif', { ' then', '' } },
         { 'if',   { ' then', 'if' } },
         { 'case', { '', 'esac' } },
         { '',     { ' do', 'done' } },
      },
      zsh = {
         { 'elif', { ' then', '' } },
         { 'if',   { ' then', 'if' } },
         { 'case', { '', 'esac' } },
         { '',     { ' do', 'done' } },
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
}

local match =
    function(str, pat)
       if vim.fn.match(str, pat) ~= -1 then
          return true
       end
       return false
    end

local function esc(str)
   return vim.api.nvim_replace_termcodes(str, true, false, true)
end

local unpack = unpack or table.unpack
local M = {}
M.setup = function(opts)
   local indent_installed, indent = pcall(require, 'indent')

   if indent_installed == false then
      print("indent.nvim is not installed can't setup expand.nvim")
      return
   end

   M.config = vim.tbl_deep_extend("force", default, opts or {})
   vim.keymap.set('i', M.config.hotkey, function()
      local pair_open, pair_close = '{', '}'

      local checks = M.config.filetypes[vim.o.filetype]
      if checks then
         OLD_magic = vim.o.magic
         vim.o.magic = OLD_magic
         local line = vim.api.nvim_get_current_line()
         local success = false
         for i = 1, #checks - 1, 1 do
            if type(checks[i][MATCH]) == 'function' then
               if checks[i][MATCH]() then
                  pair_open, pair_close = unpack(checks[i][PAIRS])
                  success = true
                  break
               end
            end
            if type(checks[i][MATCH]) == 'string' then
               vim.o.magic = true
               if match(line, checks[i][MATCH]) then
                  pair_open, pair_close = unpack(checks[i][PAIRS])
                  success = true
                  break
               end
            else
               print(checks[i][MATCH], "has an invalid match type (not a function or a string)")
            end
         end
         if not success and #checks ~= 0 then
            pair_open, pair_close = unpack(checks[#checks][PAIRS])
         end
      end
      indent.enable_ctrl_f_formatting()
      local keys = esc('<C-g>u' .. '<end>' ..
         pair_open .. '<cr><cr>' ..
         pair_close .. '<C-f><up><C-f>' ..
         '<cmd>lua require(\'indent\').restore_user_configuration()' ..
         ' vim.o.magic = OLD_magic<cr>')
      if __EXPAND_IS_TESTING then
         -- tests loads every test into the typeahead bufer at once
         -- because i couldn't find a way to flush it
         -- which makes us need to keep placing the pairs before the tests with i
         -- we also need to redraw to to allow future expantions to detect us (custom)
         -- this already happens in the normal case
         vim.api.nvim_feedkeys(keys .. esc('<cmd>redraw<cr>'), 'i', false)
         return
      end
      vim.api.nvim_feedkeys(keys, 'n', false)
   end)
end

return M
