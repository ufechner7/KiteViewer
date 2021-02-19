
## How to create a SystemImage with Makie.jl to reduce the startup time

First make sure the KiteViewer directory is the current directory. Then execute the following commands:

```julia
julia --project

using Pkg
Pkg.add("PackageCompiler")

exit()
```
```julia
julia --project

using Makie, GLMakie, Arrow, MeshIO, RecursiveArrayTools, Revise, Rotations, StaticArrays, StructArrays, YAML

using PackageCompiler

PackageCompiler.create_sysimage(
    [:Makie, :GLMakie, :Arrow, :MeshIO, :RecursiveArrayTools, :Revise, :Rotations, :StaticArrays, :StructArrays, :YAML];
    sysimage_path="MakieSys.so",
    precompile_execution_file=joinpath("test", "test_for_precompile.jl")
)

exit()
```

Finally, use the following command to launch Julia:
```julia -J MakieSys.so --project```

or the following command to launch the GUI without julia command line:
```./kiteviewer.sh```

On my computer (i7-7700K) this reduced the startup time from 41s to 4s.
