local Test = Test or print
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

-- weirdly running 20000 tests only takes around 20 seconds and most of the time is used loading the tests
