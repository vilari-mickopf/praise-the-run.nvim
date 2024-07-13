## Praise The Run

Plugin for compiling/running python, c/c++, rust, lua, and sh scripts. It identifies the project root by traversing upwards in the directory tree, searching for specified identifiers. If no identifiers are found, the directory of the current file is assumed to be the root. You can also set custom run commands per project with a specified project file, which will be automatically included in the list of root identifiers.


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
./<script> <args>
```


### Install

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

You can define custom runners for each language:

```lua
-- Every runner func should return commnad as a string
-- The first command will always be `cd <root>` regardless of runner function
local function custom_python_runner(root, args)
    ...
end

local function custom_c_runner(root, args)
    ...
end

local function custom_rust_runner(root, args)
    ...
end

local function custom_lua_runner(root, args)
    ...
end

local function custom_sh_runner(root, args)
    ...
end

require('praise-the-run').setup({
    python = {
        project_file = '.pyproject',
        root_identifier = {'.git', '.svn'},
        run = custum_python_runner
    },

    c = {
        project_file = '.cproject',
        root_identifier = {'Makefile', 'makefile', 'CMakeLists.txt', '.git', '.svn'},
        run = custom_c_runner
    },
    cpp = c,

    rust = {
        project_file = '.rustproject',
        root_identifier = {'Cargo.toml', '.git', '.svn'},
        run = custom_rust_runner
    },

    lua = {
        project_file = '.luaproject',
        root_identifier = {'lua_modules', '.git', '.svn'},
        run = custom_lua_runner
    },

    sh = {
        project_file = '.shproject',
        root_identifier = {'.git', '.svn'},
        run = custom_sh_runner
    }
})
```

### Run

To run the configured commands:

```lua
require('praise-the-run.project').run()
```

or with arguments:

```lua
require('praise-the-run.project').run('--some --args')
```


### Project configuration (optional)

Example project file:

```json
{
    "pre": ["./autoconfig"], /* List of pre-run commands */
    "run": "make",           /* Command that should be run */
    "args": "-j",            /* Arguments to run command */
    "post": ["./run-bin"],   /* List of pros-run commands */
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

If `require('praise-the-run.project').run(<args>)` is used, the provided arguments (<args>) will override the arguments specified in the configuration file.


#### Opening the Project File
To open the project file in a split window, use:

```lua
require('praise-the-run.project').open_project_file()
```

If the file doesn't exist, a dummy project file with all fields empty will be created automatically.


#### My keybindings
```vim
nmap <silent> <buffer> <leader>c :wa<Cr>:lua require('praise-the-run.project').run('')<Cr>
nmap <silent> <buffer> <leader>C :wa<CR>:lua << EOF
require('praise-the-run.project').run(require('praise-the-run.project').get_user_input('Args: '))
EOF
nmap <silent> <buffer> <leader>p :lua require('praise-the-run.project').open_project_file()<Cr>
```
