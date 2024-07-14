local M = {}


local function find_lsp_root()
    local clients = vim.lsp.get_clients()
    if next(clients) == nil then
        return nil
    end

    for _, client in pairs(clients) do
        if client.config.root_dir then
            local root_dir = client.config.root_dir
            if vim.fn.fnamemodify(vim.fn.expand('%:p'), ':h'):sub(1, #root_dir) == root_dir then
                return root_dir
            end
        end
    end

    return nil
end


local function find_root(patterns)
    local root = find_lsp_root()
    if root then
        return root
    end

    local path = vim.fn.expand('%:p:h')

    while path ~= '/' do
        for _, pattern in ipairs(patterns) do
            local test_path = path .. '/' .. pattern
            if vim.loop.fs_stat(test_path) then
                return path
            end
        end
        path = vim.fn.fnamemodify(path, ':h')  -- Go up one directory level
    end

    return vim.fn.expand('%:p:h')
end


local function read_project_file(path)
    local file = io.open(path, 'r')
    if not file then
        print('Could not open file: ' .. path)
        return
    end

    local content = file:read('*a')
    file:close()

    return vim.json.decode(content)
end


function M.call(command)
    -- Open a split, run the command in a terminal, and set the buffer name
    vim.cmd(string.format([[
        split
        terminal %s
        call cursor(line('w$'), col('.'))
    ]], command))
end


local function append(str, items, pre, post)
    if items and #items > 0 then
        for _, i in ipairs(items) do
            str = str .. pre .. i .. post
        end
    end
    return str
end


local function run_with_project_config(run, args, project_config)
    local command = append(' ', project_config.pre, '', ' && ')

    if project_config.run ~= '' then
        command = command .. project_config.run
        if args ~= '' then
            command = command .. ' ' .. args
        elseif project_config.args ~= '' then
            command = command .. ' ' .. project_config.args
        end
    else
        command = command .. run
        if args == '' and project_config.args ~= '' then
            command = command .. ' ' .. project_config.args
        end
    end

    return append(command, project_config.post, ' && ', '')
end


function M.run(lang_config, args)
    if not args then
        args = ''
    end

    if not lang_config then
        print('Runner not configured for ' .. vim.bo.filetype)
        return
    end

    local patterns = lang_config.root_identifier
    table.insert(patterns, lang_config.project_file)

    local root = find_root(patterns)
    local command = lang_config.run(root, args)
    if not command or command == '' then
        return
    end

    local project_file = root .. '/' .. lang_config.project_file
    if vim.fn.findfile(project_file) ~= '' then
        local project_config = read_project_file(project_file)
        if not project_config then
            return
        end

        command = run_with_project_config(command, args, project_config)
    else
        command = ' ' .. command
    end

    return 'cd ' .. root .. ' &&' .. command
end


function M.prompt_and_run(lang_config)
    vim.fn.inputsave()
    local args = vim.fn.input('Args: ')
    vim.fn.inputrestore()

    if not args or args == '' then
        return
    end

    return M.run(lang_config, args)
end


function M.open_project_file(lang_config)
    if not lang_config then
        print('Plugin not configured for ' .. vim.bo.filetype .. 'project.')
        return
    end

    local root = find_root(lang_config.root_identifier)
    local project_file = root .. '/' .. lang_config.project_file
    if vim.fn.findfile(project_file) ~= '' then
        vim.cmd('split ' .. project_file)
    else
        local dummy_project_json = '{\n' ..
                                   '    "pre": [],\n' ..
                                   '    "run": "",\n' ..
                                   '    "args": "",\n' ..
                                   '    "post": []\n' ..
                                   '}'

        local file = io.open(project_file, 'w')
        if file then
            file:write(dummy_project_json)
            file:close()

            vim.cmd('split ' .. project_file)
            vim.cmd('%!python -m json.tool')
            vim.cmd('write')
        end
    end
end


return M
