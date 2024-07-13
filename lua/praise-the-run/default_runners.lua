local function python(root, args)
    local command = 'python ' .. vim.api.nvim_buf_get_name(0)
    if args ~= '' then
        command = command .. ' ' .. args
    end
    return command
end


local function c(root, args)
    if vim.fn.findfile(root .. '/' .. 'CMakeLists.txt') ~= '' then
        return ' cd build && cmake .. ' .. args .. ' && make -j'
    else
        if vim.fn.glob(root .. '/*[Mm]akefile') == '' then
            local script_dir = debug.getinfo(2, 'S').source:sub(2):match('(.*/)')
            local input = vim.loop.fs_open(script_dir .. '/MakefileTemplate', 'r', 438)
            assert(input, 'Could not open source file')
            local output = vim.loop.fs_open(root .. '/Makefile', 'w', 438)
            assert(output, 'Could not open destination file')

            local stat = vim.loop.fs_fstat(input)
            local data = vim.loop.fs_read(input, stat.size, 0)
            vim.loop.fs_write(output, data, 0)

            vim.loop.fs_close(input)
            vim.loop.fs_close(output)
        end
        return ' make -j ' .. args
    end
end


local cpp = c


local function rust(root, args)
    if vim.fn.findfile(root .. '/Cargo.toml') == '' then
        print('Cargo.toml file not present.')
        return
    end

    local command = 'cargo run'
    if args ~= '' then
        command = command .. ' -- ' .. args
    end

    return command
end


local function lua(root, args)
    local command = 'lua'
    if vim.fn.findfile(root .. '/lua_modules') ~= '' then
        command = './lua'
    end

    command = command .. ' ' .. vim.api.nvim_buf_get_name(0)
    if args ~= '' then
        command = command .. ' ' .. args
    end

    return command
end


local function sh(root, args)
    local command = 'chmod +x ' .. vim.api.nvim_buf_get_name(0) .. ' && '
    command = command .. vim.api.nvim_buf_get_name(0)
    if args ~= '' then
        command = command .. ' ' .. args
    end
    return command
end


return {
    python = python,
    c = c,
    cpp = cpp,
    rust = rust,
    lua = lua,
    sh = sh
}
