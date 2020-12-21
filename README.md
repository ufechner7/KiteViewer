# KiteViewer.jl
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
using KiteViewer
main()
```

Use the right mouse butto to zoom and the left mouse button to pan
the 3D view. 
