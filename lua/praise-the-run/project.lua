local M = {}


local function find_root(patterns)
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


local function call(command)
    -- Open a split, run the command in a terminal, and set the buffer name
    vim.cmd(string.format([[
        exe 'split' | exe 'terminal %s'
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


local function run_from_project_file(run, args, procject_config)
    local command = append('', procject_config.pre, ' ', ' &&')

    local run_command = procject_config.run
    if args ~= '' then
        run_command = run_command .. ' ' .. args
    elseif procject_config.args ~= '' then
        run_command = run_command .. ' ' .. procject_config.args
    end

    if run_command == '' then
        run_command = run
    end
    command = command .. ' ' .. run_command

    return append(command, procject_config.post, ' && ', '')
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

        command = run_from_project_file(command, args, project_config)
    else
        command = ' ' .. command
    end

    call('cd ' .. root .. ' &&' .. command)
end


function M.prompt_and_run(lang_config)
    vim.fn.inputsave()
    local args = vim.fn.input('Args: ')
    vim.fn.inputrestore()

    if not args or args == '' then
        return
    end

    M.run(lang_config, args)
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
