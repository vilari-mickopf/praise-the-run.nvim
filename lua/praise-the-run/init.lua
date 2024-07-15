local default_runners = require('praise-the-run.default_runners')
local project = require('praise-the-run.project')

local M = {}


local function validate_language_config(lang, config)
    if not config.project_file then
        config.project_file = '.' .. lang .. 'project'
    end

    if not config.root_identifier then
        config.root_identifier = {'.git', '.svn'}
    end

    if not config.run then
        error('Run function for language ' .. lang .. ' is not specified.')
    end
end


function M.setup(user_config)
    local config = user_config or {}

    local default_config = {
        call = project.call,
        languages = {
            python = {
                project_file = '.pyproject',
                root_identifier = {'.git', '.svn'},
                run = default_runners.python
            },
            c = {
                project_file = '.cproject',
                root_identifier = {'[Mm]akefile', 'CMakeLists.txt', '.git', '.svn'},
                run = default_runners.c
            },
            cpp = {
                project_file = '.cproject',
                root_identifier = {'[Mm]akefile', 'CMakeLists.txt', '.git', '.svn'},
                run = default_runners.cpp
            },
            zig = {
                project_file = '.zigproject',
                root_identifier = {'[Mm]akefile', 'zig.build', '.git', '.svn'},
                run = default_runners.zig
            },
            make = {
                project_file = '.cproject',
                root_identifier = {'[Mm]akefile', 'CMakeLists.txt', '.git', '.svn'},
                run = default_runners.make
            },
            cmake = {
                project_file = '.cproject',
                root_identifier = {'CMakeLists.txt', '.git', '.svn'},
                run = default_runners.cmake
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
            },
            haskell = {
                project_file = '.hsproject',
                root_identifier = {'*.cabal', '.git', '.svn'},
                run = default_runners.haskell
            },
            matlab = {
                project_file = '.mproject',
                root_identifier = {'.git', '.svn'},
                run = default_runners.matlab
            },
            markdown = {
                project_file = '.mdproject',
                root_identifier = {'.git', '.svn'},
                run = default_runners.markdown
            },
            rmd = {
                project_file = '.rmdproject',
                root_identifier = {'.git', '.svn'},
                run = default_runners.rmarkdown
            },
            tex = {
                project_file = '.texproject',
                root_identifier = {'.git', '.svn'},
                run = default_runners.tex
            },
            plaintex = {
                project_file = '.texproject',
                root_identifier = {'.git', '.svn'},
                run = default_runners.tex
            }
        }
    }

    -- Merge user config with default config
    config = vim.tbl_deep_extend('force', default_config, config)

    M.languages = M.languages or {}

    -- Assign the merged configuration to M
    M.call = config.call
    for lang, settings in pairs(config.languages) do
        validate_language_config(lang, settings)
        M.languages[lang] = settings
    end

    -- Add new languages if specified
    if user_config and user_config.languages then
        for lang, settings in pairs(user_config.languages) do
            if not M.languages[lang] then
                validate_language_config(lang, settings)
                M.languages[lang] = settings
            end
        end
    end
end


function M.run(args)
    local command = project.run(M.languages[vim.bo.filetype], args)
    if not command then
        return
    end
    M.call(command)
end

vim.api.nvim_create_user_command('ProjectRun', function()
    M.run()
end, {})


function M.prompt_and_run()
    local command = project.prompt_and_run(M.languages[vim.bo.filetype])
    if not command then
        return
    end
    M.call(command)
end

vim.api.nvim_create_user_command('ProjectRunWithArgs', function()
    M.prompt_and_run()
end, {})


function M.open_project_file()
    project.open_project_file(M.languages[vim.bo.filetype])
end

vim.api.nvim_create_user_command('OpenProjectFile', function()
    M.open_project_file()
end, {})


return M
