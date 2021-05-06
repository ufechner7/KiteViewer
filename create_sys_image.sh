#!/bin/bash -eu
if test -f "MakieSys.so"; then
    cp MakieSys.so MakieSys.so.bak
fi
julia --project -e "include(\"./test/update_packages.jl\");"
julia --project -e "using Pkg; Pkg.precompile()"
julia --project -e "include(\"./test/create_sys_image.jl\");"
