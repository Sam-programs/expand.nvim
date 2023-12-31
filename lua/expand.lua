local MATCH = 1
local PAIRS = 2
local OPT = 3
local sh_rules = {
   { 'elif',  { ' ;then', '' },  { endpair_new_line = false } },
   { 'if',    { ' ;then', 'fi' } },
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
         { '.*(.*)',             { '{', '}' } },
         { 'struct',             { '{', '};' } },
      },
      cpp = {
         { 'namespace',          { '{', '}' } },
         { '.*(.*)',             { '{', '}' } },
         { 'class',              { '{', '};' } },
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

---@diagnostic disable-next-line: deprecated
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

      local rules = M.config.filetypes[vim.o.filetype]
      local old_magic = vim.o.magic
      local chosen_rule = nil
      if rules then
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
         end
      end
      keys = esc('<C-g>u<space><bs>' .. end_key ..
         pair_open .. new_lines ..
         pair_close .. '<C-f>' .. up_movement .. '<C-g>u' ..
         '<cmd>lua require(\'indent\').restore_user_configuration()' ..
         ' vim.o.magic = ' .. (old_magic and "true" or "false") .. 'OLD_magic<cr>')
      indent.enable_ctrl_f_formatting()
      ---@diagnostic disable-next-line: undefined-global
      vim.api.nvim_feedkeys(keys, 'n', false)
   end)
end

return M

