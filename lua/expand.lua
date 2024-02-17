local MATCH = 1
local PAIRS = 2
local OPT = 3
local sh_rules = {
    { 'elif',  { ' ;then', '' },   { lua_pattern = true, endpair_new_line = false } },
    { 'if',    { ' ;then', 'fi' }, { lua_pattern = true } },
    { 'case',  { '', 'esac' },     { lua_pattern = true } },
    { 'while', { ' do', 'done' },  { lua_pattern = true } },
    { 'for',   { ' do', 'done' },  { lua_pattern = true } },
    { '',      { '{', '}' } },
}
local default = {
    filetypes = {
        python = {
            { '', { ':', '' }, { endpair_new_line = false } },
        },
        lua = {
            -- regex for a lua variable
            { '%s*%w*%s*[a-zA-z.]+%s*=%s*$', { '{', '}' },       { lua_pattern = true } },
            -- if we are expanding on an unnamed function might as well add the pairs
            { 'function[^(]*$',              { '()', 'end' },    { lua_pattern = true, go_to_end = false } },
            { 'function',                    { '', 'end' },      { lua_pattern = true } },
            { 'if',                          { ' then', 'end' }, { lua_pattern = true } },
            { 'loops',                       { ' do', 'end' },   { lua_pattern = true } },
        },
        sh = sh_rules,
        bash = sh_rules,
        zsh = sh_rules,
        c = {
            { '.*(.*)',            { '{', '}' },  { lua_pattern = false } },
            { 'else',              { '{', '}' },  { lua_pattern = true } },
            -- an empty line is likely in a table
            { '^%s*$',             { '{', '},' }, { lua_pattern = true } },
            { '^%s*\\.%w+%s*=%s*', { '{', '},' }, { lua_pattern = true } },
            { 'struct',            { '{', '};' } },
        },
        cpp = {
            { '.*(.*)',            { '{', '}' },  { lua_pattern = false } },
            { 'namespace',         { '{', '}' },  { lua_pattern = true } },
            { 'else',              { '{', '}' },  { lua_pattern = true } },
            -- an empty line is likely in a table
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

local match = function(str, pat, lua_pattern)
    if (lua_pattern) then
        return str:match(pat) and true or false
    end
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
M.config = {}
M.get_pairs = function(pairs)
    if (type(pairs) == 'function') then
        return pairs()
    end
    return unpack(pairs)
end

M.setup = function(opts)
    local indent_installed, indent = pcall(require, 'indent')

    if indent_installed == false then
        vim.notify("indent.nvim is not installed can't setup expand.nvim", vim.log.levels.WARN, {})
        return
    end
    local hotkey = opts.hotkey or '<C-Space>'
    opts.hotkey = nil
    M.config[hotkey] = vim.tbl_deep_extend("force", default, opts or {})
    vim.keymap.set('i', hotkey, function()
        local config = M.config[hotkey]
        local rules = config.filetypes[vim.o.filetype] or {}
        local chosen_rule = nil
        local line = vim.api.nvim_get_current_line()
        for i, rule in pairs(rules) do
            -- nil if the match type is invalid
            local matched = nil
            if type(rule[MATCH]) == 'function' then
                -- or false makes sure it's not nil
                matched = rule[MATCH]() or false
            end
            if type(rule[MATCH]) == 'string' then
                local old_magic = vim.o.magic
                vim.o.magic = true
                local lua_pattern = config.default_options.lua_pattern
                if rule[OPT] and rule[OPT].lua_pattern then
                    lua_pattern = rule[OPT].lua_pattern
                end
                matched = match(line, rule[MATCH], lua_pattern)
                vim.o.magic = old_magic
            end
            if matched == true then
                chosen_rule = rule
                break
            end
            if matched == nil then
                vim.notify(
                    "expand.nvim: rule " ..
                    i .. "for " .. vim.o.ft .. " has an invalid match type (not a function or a string)",
                    vim.log.levels.WARN, {})
            end
        end
        if chosen_rule == nil then
            chosen_rule = config.default_rule
            if (#rules ~= 0) then
                chosen_rule = rules[#rules]
            end
        end
        local pair_open, pair_close = M.get_pairs(chosen_rule[PAIRS])
        if (type(pair_open) ~= 'string' or type(pair_close) ~= 'string') then
            return
        end
        local end_key = '<end>'
        local new_lines = '<cr><cr>'
        local up_movement = '<up><C-f>'
        local opt = chosen_rule[OPT] or {}
        opt = vim.tbl_deep_extend("keep", opt, config.default_options)
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
        -- <space><bs> is a hack to trigger an undoblock start
        local keys = esc('<C-g>u<space><bs>' ..
            end_key ..
            pair_open .. new_lines ..
            pair_close .. '<C-f>' .. up_movement .. '<C-g>u' ..
            '<cmd>lua require(\'indent\').restore_user_configuration()<cr>')
        indent.enable_ctrl_f_formatting()
        ---@diagnostic disable-next-line: undefined-global
        vim.api.nvim_feedkeys(keys, 'in', false)
    end)
end

M.unsetup = function(opts)
    vim.keymap.del(opts.hotkey)
    M.config[opts.hotkey] = nil
end

return M
