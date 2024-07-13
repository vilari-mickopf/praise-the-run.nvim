local configs = require('praise-the-run')


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


local function open_project_file()
    local config = configs[vim.bo.filetype]
    if not config then
        print('Plugin not configured for ' .. vim.bo.filetype .. 'project.')
        return
    end

    local root = find_root(config.root_identifier)
    local project_file = root .. '/' .. config.project_file
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


local function run_with_config(run, args, config)
    local command = append('', config.pre, ' ', ' &&')

    local run_command = config.run
    if args ~= '' then
        run_command = run_command .. ' ' .. args
    elseif config.args ~= '' then
        run_command = run_command .. ' ' .. config.args
    end

    if run_command == '' then
        run_command = run
    end
    command = command .. ' ' .. run_command

    return append(command, config.post, ' && ', '')
end


local function run(args)
    if not args then
        return
    end

    local config = configs[vim.bo.filetype]
    if not config then
        print('Runner not configured for ' .. vim.bo.filetype)
        return
    end

    local patterns = config.root_identifier
    table.insert(patterns, config.project_file)

    local root = find_root(patterns)
    local command = config.run(root, args)
    if not command or command == '' then
        return
    end

    local project_file = root .. '/' .. config.project_file
    if vim.fn.findfile(project_file) ~= '' then
        local project_file_config = read_project_file(project_file)
        if not project_file_config then
            return
        end

        command = run_with_config(command, args, project_file_config)
    else
        command = ' ' .. command
    end

    call('cd ' .. root .. ' &&' .. command)
end


local function get_user_input(prompt)
    vim.fn.inputsave()
    local user_input = vim.fn.input(prompt)
    vim.fn.inputrestore()

    if user_input == '' then
        return nil
    end

    return user_input
end


return {
    run = run,
    open_project_file = open_project_file,
    get_user_input = get_user_input
}
