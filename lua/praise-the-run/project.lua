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
        print('Not configured for ' .. vim.bo.filetype .. 'project.')
        return
    end

    local root = find_root(config.root_identifier)
    if vim.fn.findfile(root .. '/' .. config.project_file) ~= '' then
        -- create dummy project file
    else
        -- open project file
    end
end


local function run(args)
    local config = configs[vim.bo.filetype]
    if not config then
        print('Runner not configured for ' .. vim.bo.filetype)
        return
    end

    local patterns = config.root_identifier
    table.insert(patterns, config.project_file)

    local root = find_root(patterns)
    config.run(root, config.project_file, args)
end


return {
    run = run,
    open_project_file = open_project_file
}
