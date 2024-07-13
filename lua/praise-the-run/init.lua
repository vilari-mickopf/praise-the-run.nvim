local default_runners = require('praise-the-run.default_runners')

local M = {}

function M.setup(user_config)
    local config = user_config or {}

    local default_config = {
        python = {
            project_file = '.pyproject',
            root_identifier = {'.git', '.svn'},
            run = default_runners.python
        },
        c = {
            project_file = '.cproject',
            root_identifier = {'Makefile', 'makefile', 'CMakeLists.txt', '.git', '.svn'},
            run = default_runners.c
        },
        cpp = {
            project_file = '.cproject',
            root_identifier = {'Makefile', 'makefile', 'CMakeLists.txt', '.git', '.svn'},
            run = default_runners.cpp
        },
        rust = {
            project_file = '.rustproject',
            root_identifier = {'Cargo.toml', '.git', '.svn'},
            run = default_runners.rust
        },
        lua = {
            project_file = '.luaproject',
            root_identifier = {'lua_modules', '.git', '.svn'},
            run = default_runners.lua
        },
        sh = {
            project_file = '.shproject',
            root_identifier = {'.git', '.svn'},
            run = default_runners.sh
        }
    }

    -- Merge user config with default config
    config = vim.tbl_deep_extend('force', default_config, config)

    -- Assign the merged configuration to M
    M.python = config.python
    M.c = config.c
    M.cpp = config.cpp
    M.rust = config.rust
    M.lua = config.lua
    M.sh = config.sh
end

return M
