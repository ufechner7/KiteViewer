
## How to create a SystemImage with Makie.jl to reduce the startup time

First make sure the KiteViewer directory is the current directory. Then execute the following commands:

```julia
julia --project

using GLMakie, Arrow, MeshIO, RecursiveArrayTools, Revise, Rotations, StaticArrays, StructArrays, YAML

using PackageCompiler

PackageCompiler.create_sysimage(
    [:GLMakie, :Arrow, :MeshIO, :RecursiveArrayTools, :Revise, :Rotations, :StaticArrays, :StructArrays, :YAML];
    sysimage_path="MakieSys.so",
    precompile_execution_file=joinpath("test", "test_for_precompile.jl")
)

exit()
```

Finally, use the following command to launch Julia:
```julia -J MakieSys.so --project```

or the following command to launch the GUI without julia command line:
```./kiteviewer.sh```

On my computer (i7-7700K) this reduced the startup time from 69s to 9s.

## Troubleshooting
### Preparation
Before running the script ```create_sys_image.sh``` it is suggested to update your packages:

```
./runjulia.sh
]resolve
instantiate
up
precompile
<backspace>
exit()
```

### Error "Cannot find crti.o" on Linux
Install the package gcc-multilib
```
sudo apt install gcc-multilib
``` 
