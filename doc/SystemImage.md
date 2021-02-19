
## How to create a SystemImage with Makie.jl to reduce the startup time
.
```julia --project
]add PackageCompiler
<backspace>

exit()
```
```
julia --project
using Makie
using PackageCompiler

PackageCompiler.create_sysimage(
    :Makie;
    sysimage_path="MakieSys.so",
    precompile_execution_file=joinpath("test", "test_for_precompile.jl")
)
```

Finally, use the following command to launch Julia:
```julia -J MakieSys.so --project```

or the following command to launch the GUI without julia command line:
```./kiteviewer2.sh```

On my computer (i7-7700K) this reduced the startup time from 41s to 11s.
