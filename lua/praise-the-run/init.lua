local default_runners = require('fitter-happier.default_runners')

local M = {}

function M.setup(user_config)
    local config = user_config or {}

    M.python = config.python or {
        project_file = '.pyproject',
        root_identifier = {'.git', '.svn'},
        run = default_runners.python
    }

    M.c = config.c or {
        project_file = '.cproject',
        root_identifier = {'Makefile', 'makefile', 'CMakeLists.txt', '.git', '.svn'},
        run = default_runners.c
    }
    M.cpp = config.cpp or M.c

    M.rust = config.rust or {
        project_file = '.rustproject',
        root_identifier = {'Cargo.toml', '.git', '.svn'},
        run = default_runners.rust
    }

    M.lua = config.lua or {
        project_file = '.luaproject',
        root_identifier = {'.git', '.svn'},
        run = default_runners.lua
    }
end

return M
