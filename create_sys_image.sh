#!/bin/bash -eu
if test -f "MakieSys.so"; then
    mv MakieSys.so MakieSys.so.bak
fi
rm -f Manifest.toml
julia --project -e "include(\"./test/update_packages.jl\");"
julia --project -e "using Pkg; Pkg.precompile()"
julia --project -e "include(\"./test/create_sys_image.jl\");"
