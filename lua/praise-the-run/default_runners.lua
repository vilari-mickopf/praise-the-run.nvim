local M = {}



function M.default_runner(command, root, args)
    -- get path relative to root
    local file_path = vim.api.nvim_buf_get_name(0)
    local relative_path = vim.fn.fnamemodify(file_path, ":." .. root)

    if string.sub(command, -1) ~= '/' then
        command = command .. ' '
    end

    command = command .. relative_path
    if args ~= '' then
        command = command .. ' ' .. args
    end

    return command
end


function M.python(root, args)
    return M.default_runner('python', root, args)
end


function M.make(root, args)
    return ' make -j ' .. args
end


function M.cmake(root, args)
    return ' cd build && cmake .. ' .. args .. ' && make -j'
end


function M.c(root, args)
    if vim.fn.findfile(root .. '/' .. 'CMakeLists.txt') ~= '' then
        return M.cmake(root, args)
    else
        -- Add template makefile if not present already
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

        return M.make(root, args)
    end
end


M.cpp = M.c


function M.rust(root, args)
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


function M.lua(root, args)
    local command = 'lua'

    local stat = vim.loop.fs_stat(root .. '/lua_modules')
    if stat and stat.type == 'directory' then
        command = './lua'
    end

    return M.default_runner(command, root, args)
end


function M.sh(root, args)
    local command = 'chmod +x ' .. vim.api.nvim_buf_get_name(0) .. ' && '
    return M.default_runner(command .. './', root, args)
end


function M.markdown(root, args)
    if not string.find(args, '%-o') then
        args = args .. '-o ' .. string.gsub(vim.api.nvim_buf_get_name(0), '%.%w+$', '.pdf')
    end

    return M.default_runner('pandoc --verbose', root, args)
end


function M.rmarkdown(root, args)
    local file_path = vim.api.nvim_buf_get_name(0)
    local relative_path = vim.fn.fnamemodify(file_path, ":." .. root)

    local command = 'echo \"require(rmarkdown); render(\'' .. relative_path .. '\')\" | R'

    if args ~= '' then
        command = command .. ' ' .. args
    else
        command = command .. ' --vanilla'
    end

    return command
end


function M.tex(root, args)
    local file_path = vim.api.nvim_buf_get_name(0)
    local relative_path = vim.fn.fnamemodify(file_path, ':.' .. root)

    local pdflatex = 'pdflatex ' .. relative_path
    local bibtex= 'bibtex ' .. relative_path:gsub('%.tex$', '')
    local biber= 'biber ' .. relative_path:gsub('%.tex$', '')
    local bibliography = "grep -q 'bibliography' " .. relative_path
    local biblatex = "grep -q 'biblatex' " .. relative_path

    return string.format(
        'bash -c "%s && if %s; then if %s; then %s && %s && %s; else %s && %s && %s; fi; fi"',
        pdflatex,
        bibliography,
        biblatex,
        biber,
        pdflatex,
        pdflatex,
        bibtex,
        pdflatex,
        pdflatex
    )
end


return M
