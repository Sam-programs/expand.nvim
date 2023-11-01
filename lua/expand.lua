local MATCH = 1
local PAIRS = 2
local OPT = 3
local sh_rules = {
   { 'elif',  { ' ;then', '' },  { endpair_new_line = false } },
   { 'if',    { ' ;then', 'if' } },
   { 'case',  { '', 'esac' } },
   { 'while', { ' do', 'done' } },
   { 'for',   { ' do', 'done' } },
   { '',      { '{', '}' } },
}
local default = {
   filetypes = {
      python = {
         { '', { ':', '' }, { endpair_new_line = false } },
      },
      lua = {
         -- if we are expanding on an unnamed function might aswell add the pairs
         { 'function[^(]*$',                { '()', 'end' },   { go_to_end = false } },
         { 'function',                      { '', 'end' } },
         { 'if',                            { ' then', 'end' } },
         -- regex for a lua variable
         { '^\\s*\\w\\+\\s*\\w*\\s*=\\s*$', { '{', '}' } },
         { '',                              { ' do', 'end' } },
      },
      sh = sh_rules,
      bash = sh_rules,
      zsh = sh_rules,
      c = {
         { '.*(.*)', { '{', '}' }, {
            wrap_pair_between_match = true,
         } },
         { 'struct',             { '{', '};' } },
         -- variable regex
         { '[a-z1-9]\\s*=\\s*$', { '{', '};' } },
         { '',                   { '', '' },   { do_nothing = true } },
      },
      cpp = {
         { '.*(.*)',             { '{', '}' } },
         { 'class',              { '{', '};' } },
         { '[a-z1-9]\\s*=\\s*$', { '{', '};' } },
         { 'struct',             { '{', '};' } },
         -- variable regex
         { '',                   { '', '' },   { do_nothing = true } },
      },
   },
   hotkey = '<C-Space>',
   wrap_hotkey = '<A-Space>',
}

local unpack = unpack or table.unpack
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

local indent_installed, indent

local function optstr(opt)
   return opt and "true" or "false"
end

local function handle_wrapping(wbegin, wend, open_pair, close_pair)
   -- c-g U causes flickering
   -- stop that with lazy redrawing
   local old_lz = vim.o.lz
   vim.o.lz = true
   local line = vim.api.nvim_get_current_line()
   local row = vim.api.nvim_win_get_cursor(0)[1]
   local diff = #line - (wend + 1)
   indent.enable_ctrl_f_formatting()
   vim.api.nvim_win_set_cursor(0, { row, wbegin })
   vim.api.nvim_feedkeys(esc(open_pair .. '<cr>' ..
      '<cmd>call cursor(' .. row + 1 .. ',strlen(getline(\'.\')) - ' .. diff .. ')<cr>' .. close_pair ..
      '<cmd>redraw<cr><cmd>call cursor(' .. row + 1 .. ',strlen(getline(\'.\')) - ' .. diff + #close_pair .. ')<cr>' ..
      '<cr><C-f><up><C-f>' ..
      '<cmd>lua require(\'indent\').restore_user_configuration()<cr>' ..
      '<cmd>lua vim.o.lz = ' .. optstr(old_lz) .. '<cr>'
   ), 'n', false)
end

local function get_pairs_and_rule(rules)
   if #rules == 0 then
      return
   end
   local pair_open, pair_close, chosen_rule
   local line = vim.api.nvim_get_current_line()
   for _, rule in pairs(rules) do
      if type(rule[MATCH]) == 'function' then
         local return_value, closing_pair = rule[MATCH]()
         if return_value == true then
            pair_open, pair_close = unpack(rule[PAIRS])
            chosen_rule = rule
            break
         end
         if type(return_value) == 'string' then
            pair_open, pair_close = return_value, closing_pair
            chosen_rule = rule
            break;
         end
      elseif type(rule[MATCH]) == 'string' then
         vim.o.magic = true
         if match(line, rule[MATCH]) then
            pair_open, pair_close = unpack(rule[PAIRS])
            chosen_rule = rule
            break
         end
      else
         print(rule[MATCH], "has an invalid match type (not a function or a string)")
      end
   end
   if not chosen_rule and #rules ~= 0 then
      pair_open, pair_close = unpack(rules[#rules][PAIRS])
      chosen_rule = rules[#rules]
   end
   return pair_open, pair_close, chosen_rule
end


---@diagnostic disable-next-line: deprecated
local M = {}
M.setup = function(opts)
   indent_installed, indent = pcall(require, 'indent')
   if indent_installed == false then
      print("indent.nvim is not installed can't setup expand.nvim")
      return
   end

   M.config = vim.tbl_deep_extend("force", default, opts or {})
   vim.keymap.set('i', M.config.wrap_hotkey, function()
      local rules = M.config.filetypes[vim.o.filetype]
      local pair_open,pair_close,chosen_rule
      if rules then
         pair_open, pair_close, chosen_rule = get_pairs_and_rule(rules)
         if chosen_rule == nil  then
            return
         end
      end
      local line = vim.api.nvim_get_current_line()
      local mbegin = vim.fn.match(line, chosen_rule[MATCH])
      -- anyone has a better way to find the end pos of the match?
      local mend = mbegin + #vim.fn.matchstr(line, chosen_rule[MATCH], mbegin)
      handle_wrapping(mend, #line, pair_open, pair_close)
      vim.api.nvim_feedkeys(esc(
            '<cmd>lua vim.o.magic = ' .. optstr(old_magic) .. '<cr>'),
         'n',
         false)
   end)
   vim.keymap.set('i', M.config.hotkey, function()
      local pair_open, pair_close = '{', '}'

      local old_magic = vim.o.magic
      local chosen_rule = nil
      local rules = M.config.filetypes[vim.o.filetype]
      if rules then
         pair_open, pair_close, chosen_rule = get_pairs_and_rule(rules)
      end
      local keys = ''
      local end_key = '<end>'
      local new_lines = '<cr><cr>'
      local up_movement = '<up><C-f>'
      if chosen_rule then
         local opt = chosen_rule[OPT]
         if opt then
            if opt.do_nothing then
               return
            end
            if opt.go_to_end == false then
               end_key = ''
            end
            if opt.endpair_new_line == false then
               new_lines = '<cr>'
               up_movement = ''
            end
            if opt.wrap_pair_between_match then
               if type(chosen_rule[MATCH]) ~= 'string' then
                  print('attemped to wrap pairs between a functional rule')
                  return
               end
               local line = vim.api.nvim_get_current_line()
               local mbegin = vim.fn.match(line, chosen_rule[MATCH])
               -- anyone has a better way to find the end pos of the match?
               local mend = mbegin + #vim.fn.matchstr(line, chosen_rule[MATCH], mbegin)
               handle_wrapping(mend, #line, pair_open, pair_close)
               vim.api.nvim_feedkeys(esc(
                     '<cmd>lua vim.o.magic = ' .. optstr(old_magic) .. '<cr>'),
                  'n',
                  false)
               return
            end
         end
      end
      keys = esc('<C-g>u<space><bs>' .. end_key ..
         pair_open .. new_lines ..
         pair_close .. '<C-f>' .. up_movement .. '<C-g>u' ..
         '<cmd>lua require(\'indent\').restore_user_configuration()' ..
         ' vim.o.magic = ' .. optstr(old_magic) .. '<cr>')
      indent.enable_ctrl_f_formatting()
      ---@diagnostic disable-next-line: undefined-global
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
