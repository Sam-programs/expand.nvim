-- i recommend you don't check this file
-- it's a mess
require('expand').setup {}

-- no indenting we just want to make sure the pairs are matching the right patterns
vim.o.indentexpr = '0'

local function esc(str)
   return vim.api.nvim_replace_termcodes(str, true, false, true)
end

function Exit()
   vim.api.nvim_feedkeys(esc("<cmd>quit!<cr>"), "m", false)
end

local test_count = 0
function Handler_lines(keys,expect, err)
   test_count = test_count + 1
   --redraw to update the buffer for nvim_buf_get_lines to get updated text
   expect = vim.split(expect, '\n')
   vim.cmd('redraw')
   local lines = vim.api.nvim_buf_get_lines(0,0,-1, false)
   for i, line in pairs(expect) do
      if line ~= lines[i] or #lines ~= #expect then
         print('\n' .. vim.o.filetype.. ':',err .. ' failed\n')
         print('keys:',"\"".. keys .. "\"")
         print('expected:\n')
         for _, expected_line in pairs(expect) do
            if expected_line == '' then
               print('\n')
            else
               print(expected_line)
            end
         end
         print('\ngot:')
         for _, real_line in pairs(lines) do
            if real_line == '' then
               print('\n')
            else
               print(real_line)
            end
         end
         print('\n')
         return
      end
   end
   print(vim.o.filetype.. ':',err,'passed','#',test_count,'\n')
end

function Test(keys, expect, err, filetype)
   local it = vim.gsplit(expect, '\n')
   -- don't add an extra \n for the first line
   local formatted = it()
   for s in it do
      -- we manaully escape them for the lua command to not treat them like code end of lines
      formatted = formatted .. '\\n' .. s
   end
   expect = formatted
   -- set the filetype
   vim.api.nvim_feedkeys(esc("<cmd>set filetype=" .. filetype .. "<cr>" .. keys .. "<cmd>") .. "lua " ..
      "Handler_lines(\""..  keys .. "\",\"" .. expect .. "\",\"" .. err .. "\") " ..
      -- clear the buffer for other tests
      esc("<cr><cmd>%d<cr>"), "m", false)
end

vim.cmd("startinsert")
__EXPAND_IS_TESTING = true
vim.cmd("so tests.lua")
Exit() -- adds a quit to the end of the typeahead buffer 
