# KiteViewer
3D viewer for tethered wind drones and kites for airborne wind energy applications

## Requirements

Julia 1.5 or higher must be installed. You can download it at https://www.julialang.org/

A fast PC with 8 GB is recommended.
OpenGL must be working.

It should work on Windows, Linux and Mac, but until now only tested on Linux.

## Installation

After installing julia, create a work folder:

```
cd
mkdir repos
cd repos
```
Check out the source code:
```
git clone https://github.com/ufechner7/KiteViewer.git
cd KiteViewer
```

Launch Julia and install the depndencies:

```
julia --project
using Pkg
Pkg.instantiate()
```

Run the program and show the GUI:

```
include("src/KiteViewer.jl")
main()
```

Use the right mouse butto to zoom and the left mouse button to pan
the 3D view. 

## Fixing OpenGL problems
On a computer with Ubuntu 20.04 and Intel integrated graphics the following steps were needed to make OpenGL work:

```
sudo apt install libglfw3
cd ~/packages/julias/julia-1.5.3/lib/julia/
rm libstdc++.so.6 
```
After implementing this fix rebuild GLMakie with the following command from within Julia:

```
cd ~/repos/KiteViewer
julia --project
] 
build GLMakie
```

Removing the version of libstdc++.so.6 supplied with Julia is only needed for Julia versions older than 1.6.0 due to this bug: https://github.com/JuliaGL/GLFW.jl/issues/198