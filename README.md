## Praise The Run

Plugin for compiling/running different projects. By default python, c/c++, zig, rust, lua, sh, haskell, matlab, markdown, rmarkdown and latex are supported, but other languages can be easily added. Upon run, plugin identifies the project root from lsp. If lsp is not present/initialized, root will be determined by traversing upwards in the directory tree, searching for specified identifiers. If no identifiers are found, the directory of the current file is assumed to be the root. You can also set custom run commands per project with a specified project file, which will be automatically included in the list of root identifiers.


### Default Runners

The first command, prepended to all commands regardless of what language is used, will always be `cd <root>`.


#### python

```bash
python <script> <args>
```

#### c/c++

- With `CMakeLists.txt` in root directory:

```bash
mkdir build && cd build
cmake .. <args>
make -j
```
_***Note**: if `clean` is passed as args, `rm -rf build` will be executed instead._

- With `Makefile` in root directory:

```bash
make -j <args>
```

- If neither CMakeLists.txt nor Makefile exists, plugin will copy generic makefile that will scan all .c/.cpp files and run:

```bash
make -j <args>
```

#### zig

- With `Makefile` in root directory:

```bash
make -j <args>
```

- With `zig.build` in root directory:

```bash
zig build <args> run
```

#### rust

- With `Cargo.toml` in root directory:

```bash
cargo run -- <args>
```

#### lua

- If `lua_modules` directory exists:

```bash
./lua <script> <args>
```

- Otherwise:

```bash
lua <script> <args>
```

#### sh

```bash
chmod +x <script>
./<script> <args>
```

#### haskell

- If `*.cabal` file exists:

```bash
cabal run
```

- Otherwise:

```bash
ghc -o <dirname> <script> && ./<dirname>
```

#### matlab

```bash
octave <script> <args>
```

#### markdown

```bash
pandoc --verbose -o <script:%.pdf>
```
_***Note**: `-o script:%.pdf` will be passed only if `-o` is not present in args._

#### rmarkdown

```bash
echo "require(rmarkdown); render('<script>')" | R --vanila
```
_***Note**: `--vanila` is passed only if args are not specifed._

#### latex

```bash
sh -c "pdflatex <script> && if grep -q 'bibliography' <script>; then if grep -q 'biblatex' <script>; then biber <script:%.> && pdflatex <script> && pdflatex <script>; else bibtex <script:%.> && pdflatex <script> && pdflatex <script>; fi; fi"
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

You can customize this by using a custom call command. Personally, I prefer using the terminal in a split window. Here are some additional keybindings that allow me to close the terminal when enter is pressed:
```vim
function! TerminalMappings()
    nmap <silent><buffer> <Cr> :q! \| echo('Terminal closed')<Cr>
endfunction

augroup TerminalStuff
    au!
    au TermOpen * call TerminalMappings()
augroup end
```


#### Runners

You can override any runner with a custom function:
```lua
local function custom_runner(root, args)
    -- First command of the runner will always be `cd <root>`
    local command = '<cmd> ' .. vim.api.nvim_buf_get_name(0)
    if args ~= '' then
        command = command .. ' ' .. args
    end
    return command

    -- You can do the same as above by using default runner:
    -- return require('praise-the-run.default_runners').default_runner('<cmd>', root, args)
end

require('praise-the-run').setup({
    languages = {
        <lang> = {
            run = custom_runner
        }
    }
})
```
The runner function takes two arguments: the root path and the provided arguments. It should always return the command to be run, represented as a string.

#### Add custom support for other languages

You can configure languages that are not support. `<lang>` should match the output of `:echo &filetype` for desired file type.
```lua
require('praise-the-run').setup({
    languages = {
        <lang> = {
            project_file = '.langproject',      --> optional, if nill, .<lang>project will be assigned
            root_identifier = {'.git', '.svn'}, --> optional, if nil, this will be assigned
            run = function(root, args)          --> mandatory
                return require('praise-the-run.default_runners').default_runner('cmd', root, args)
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

If `require('praise-the-run').run(<args>)` is used, the provided arguments `<args>` will override the arguments specified in the project file.


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
nmap <silent> <leader>p :OpenProjectFile<Cr>
nmap <silent> <leader>c :wa<Cr>:ProjectRun<Cr>
nmap <silent> <leader>C :wa<Cr>:ProjectRunWithArgs<Cr>
```

------

<a href="https://opensource.org/licenses/MIT" rel="nofollow"><img src="https://camo.githubusercontent.com/a4426cbe5c21edb002526331c7a8fbfa089e84a550567b02a0d829a98b136ad0/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f4c6963656e73652d4d49542d79656c6c6f772e737667" alt="License: MIT" data-canonical-src="https://img.shields.io/badge/License-MIT-yellow.svg" height="25px"></a>
<a href="https://www.buymeacoffee.com/vilari.mickopf"><img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" height="25px"></a>
