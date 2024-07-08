local function read_config(path)
    local file = io.open(path, 'r')
    if not file then
        print('Could not open file: ' .. path)
        return
    end

    local content = file:read('*a')
    file:close()

    return vim.json.decode(content)
end


local function run(command)
    vim.cmd(string.format([[
        exe 'split' | exe 'terminal %s'
        call cursor(line('w$'), col('.'))
    ]], command))
end


local function python(root, projectfile, args)
    if vim.fn.findfile(root .. '/' .. projectfile) ~= '' then
        local config = read_config(root .. '/' .. projectfile)
        if not config then
            return
        end

        local command = 'cd ' .. root .. '&&'
        if config.pre and #config.pre > 0 then
            for _, pre_cmd in config.pre do
                command = command .. ' ' .. pre_cmd .. '&&'
            end
        end

        local run_command = config.path
        if not run_command then
            run_command = vim.api.nvim_buf_get_name(0)
        end
        command = command .. run_command

        if args and #args > 0  then
            for _, arg in ipairs(args) do
                command = command .. ' ' .. arg
            end
        else
            if config.args and #config.args > 0 then
                for _, arg in ipairs(config.args) do
                    command = command .. ' ' .. arg
                end
            end
        end

        if config.post and #config.post > 0 then
            for _, post_cmd in config.post do
                command = command .. '&& ' .. post_cmd
            end
        end

        run(command)
    else
        local command = vim.api.nvim_buf_get_name(0)
        if args and #args > 1 then
            for _, arg in ipairs(args) do
                command = command .. ' ' .. arg
            end
        end
        run('cd ' .. root .. '&& python ' .. command)
    end
end


local function c(root, projectfile, args)
    if vim.fn.findfile(root .. '/' .. projectfile) ~= '' then
        local config = read_config(root .. '/' .. projectfile)
        if not config then
            return
        end
    else
        local command = 'cd ' .. root .. '&& '
        if vim.fn.findfile(root .. '/' .. 'CMakeLists.txt') ~= '' then
            run(command .. 'cd build && cmake ..')
        else
            if vim.fn.glob(root .. '/*[Mm]akefile') == '' then
                -- copy default makefile
            end
            run(command .. 'make')
        end
    end
end


local cpp = c


local function rust(root, projectfile, args)
    if vim.fn.findfile(root .. '/' .. projectfile) ~= '' then
        local config = read_config(root .. '/' .. projectfile)
        if not config then
            return
        end
    else
        local command = 'cd ' .. root .. '&& '
        if vim.fn.findfile(root .. '/Cargo.toml') ~= '' then
            run(command .. 'cargo build')
        end
    end
end


local function lua(root, projectfile, args)
    if vim.fn.findfile(root .. '/' .. projectfile) ~= '' then
        local config = read_config(root .. '/' .. projectfile)
        if not config then
            return
        end
    else
        local command = 'cd ' .. root .. '&& '
        if vim.fn.findfile(root .. '/lua_modules') ~= '' then
            run(command .. './lua ' .. vim.api.nvim_buf_get_name(0))
        else
            run(command .. 'lua ' .. vim.api.nvim_buf_get_name(0))
        end
    end
end


return {
    python = python,
    c = c,
    cpp = cpp,
    rust = rust,
    lua = lua
}
