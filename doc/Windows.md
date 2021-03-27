# Windows

If you want to use KiteViewer on Windows, I suggest to install

1. a decent editor, for example VSCodium  
   You can download it from https://github.com/VSCodium/vscodium/releases  
   At the time of writing you would need the file **VSCodiumSetup-x64-1.52.1.exe**

2. Git for Windows. You can download it at:
   https://git-scm.com/download/win
   During installation, selec VSCodium (or your prefered editor) as editor and select
   bash as your prefered terminal.
3. Julia. During installation select "Add Julia to the path."  
   You can download it from https://julialang.org/downloads/ 
   At the time of writing version 1.6.0 is suggested.

Git for Windows will not only provide the git version control system, but also a bash shell. When using the bash shell you can use the same commands that I am suggesting in [README.md](../README.md)  for Linux.

## Important bash commands

### Print the current directory

`pwd`

### Change the current directory

`cd`

### List the content of the current directory

`ls`

`ls -la`

The second version prints more information about each file.

### Start Julia

`julia --project` or  

`./runjulia.sh`

This launches julia and uses the packages of the file Project.toml as environment.
The second version uses the system image automatically (if available) and also loads
Revise for speedy development.

### Quit Julia

`exit()`

### Update KiteViewer

`git pull`

This might fail if you made changes to KiteViewer.jl yourself.

In that case create a backup copy of your version, check out the original version with

`git checkout src/KiteViewer.jl`

and then try  `git pull` again.

## Update all packages
```
./runjulia.sh
]resolve
instantiate
up
precompile
<backspace>
exit()
```
If you are working with a precompiled system image this needs to be re-compiled after a package update by running `./create_sys_image.sh` .

## Using VSCodium
Use the menu "Open file or directory..." to opent the folder "repos/KiteViewer"

Then open the file src/KiteViewer.jl in the Explorer on the left.

Use the menu entry "View->Terminal" to open a Terminal. In the terminal launch julia with the command  
julia --project


