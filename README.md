## Praise The Run

Plugin for compiling/running project. By default python, c/c++, rust, lua, and sh are supported, but other languages can be easily added. Upon run, plugin identifies the project root by traversing upwards in the directory tree, searching for specified identifiers. If no identifiers are found, the directory of the current file is assumed to be the root. You can also set custom run commands per project with a specified project file, which will be automatically included in the list of root identifiers.


### Default Runners

#### python
```bash
cd <root>
python <current_script> <args>
```

#### c/c++

- With `CMakeLists.txt` in root directory:

```bash
cd <root>
mkdir build && cd build
cmake .. <args>
make -j
```

- With `Makefile` in root directory:

```bash
cd <root>
make -j <args>
```

- If neither CMakeLists.txt nor Makefile exists, plugin will copy generic makefile that will scan all .c/.cpp files and run:

```bash
cd <root>
make -j <args>
```

#### rust

```bash
cd <root>
cargo run -- <args>
```

#### lua

- If `lua_modules` directory exists:

```bash
cd <root>
./lua <args>

```
- Otherwise:

```bash
cd <root>
lua <args>
```

#### sh

```bash
cd <root>
chmod +x <script>
<script> <args>
```


### Installation

Add the following to your neovim configuration:

```lua
{
    'vilari-mickopf/praise-the-run.nvim',
    config = function()
        require('praise-the-run').setup()
    end
}
```


### Configuration (optional)

Default configuration:
```lua
require('praise-the-run').setup({
    call = require('praise-the-run.project').call,
    languages = {
        python = {
            project_file = '.pyproject',
            root_identifier = {'.git', '.svn'},
            run = require('praise-the-run.default_runners').python,
        },

        c = {
            project_file = '.cproject',
            root_identifier = {'Makefile', 'makefile', 'CMakeLists.txt', '.git', '.svn'},
            run = require('praise-the-run.default_runners').c,
        },

        cpp = {
            project_file = '.cproject',
            root_identifier = {'Makefile', 'makefile', 'CMakeLists.txt', '.git', '.svn'},
            run = require('praise-the-run.default_runners').cpp,
        },

        rust = {
            project_file = '.rustproject',
            root_identifier = {'Cargo.toml', '.git', '.svn'},
            run = require('praise-the-run.default_runners').rust,
        },

        lua = {
            project_file = '.luaproject',
            root_identifier = {'lua_modules', '.git', '.svn'},
            run = require('praise-the-run.default_runners').lua,
        },

        sh = {
            project_file = '.shproject',
            root_identifier = {'.git', '.svn'},
            run = require('praise-the-run.default_runners').sh,
        }
    }
})
```

#### Call command

Default call function will run specified command in integrated terminal:
```vim
exe 'split' | exe 'terminal %s'
call cursor(line('w$'), col('.'))
```

You can change this with custom call command that is using telescope or whatever you
desire. I like using terminal, and I also use following keybinding:
```vim
function! TerminalMappings()
    nmap <silent><buffer> <Cr> :q! \| echo('Terminal closed')<Cr>
endfunction

augroup TerminalStuff
    au!
    au TermOpen * call TerminalMappings()
augroup end
```
Which is allowing me to close the terminal when enter is pressed.


#### Runners

You can override runners with custom function:
```lua
local function custom_runner(root, args)
    -- First command of the runner will always be `cd <root>`
    local command = '<cmd> ' .. vim.api.nvim_buf_get_name(0)
    if args ~= '' then
        command = command .. ' ' .. args
    end
    return command

    -- You can do the same as above by using default runner:
    -- return require('praise-the-run.default_runners').default_runner('<cmd>', args)
end

require('praise-the-run').setup({
    languages = {
        <lang> = {
            run = custom_runner
        }
    }
})
```
Runner function is taking two arguments, the root path and provided arguments.
Function should always return command that should be run, represented as a string.

#### Add custom support for other languages

You configure languages that are not support. <lang> should match output of `:echo &filetype` for desired file type.

```lua
require('praise-the-run').setup({
    languages = {
        <lang> = {
            project_file = '.langproject',      --> optional, if nill, .<lang>project will be assigned
            root_identifier = {'.git', '.svn'}, --> optional, if nil, this will be assigned
            run = function(root, args)          --> mandatory
                return require('praise-the-run.default_runners').default_runner('cmd', args)
            end
        }
    }
})
```


### Running

To compile/run language of the current file:

```lua
require('praise-the-run').run()
```

or with arguments:

```lua
require('praise-the-run').run('--some --args')
```

or with vim commands:

```vim
:ProjectRun
:ProjectRunWithArgs
```


### Project configuration (optional)

Example project file:

```json
{
    "pre": ["./autoconfig"], /* List of pre-run commands */
    "run": "make",           /* Command that should be run */
    "args": "-j",            /* Arguments to run command */
    "post": ["./run-bin"],   /* List of post-run commands */
}
```

Can be particularly useful for python projects where you need to run a specific script consistently while editing other scripts:

```json
{
    "pre": [],
    "run": "python path/to/main.py",
    "args": "--some-arg",
    "post": [],
}
```

If `require('praise-the-run').run(<args>)` is used, the provided arguments (<args>) will override the arguments specified in the configuration file.


#### Opening the Project File
To open the project file in a split window, use:

```lua
require('praise-the-run').open_project_file()
```

or use vim command:

```vim
:OpenProjectFile
```

If the file doesn't exist, a dummy project file with all fields empty will be created automatically in root directory.


#### My keybindings
```vim
nmap <silent> <buffer> <leader>p :OpenProjectFile<Cr>
nmap <silent> <buffer> <leader>c :wa<Cr>:ProjectRun<Cr>
nmap <silent> <buffer> <leader>C :wa<Cr>:ProjectRunWithArgs<Cr>
```
