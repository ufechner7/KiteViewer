#!/bin/bash -eu
branch=$(git rev-parse --abbrev-ref HEAD)
if [[ $branch == "main" ]]
    branch=""
fi
if test -f "MakieSys${branch}.so"; then
    mv MakieSys${branch}.so MakieSys${branch}.so.bak
fi
rm -f Manifest.toml
julia --project -e "include(\"./test/update_packages.jl\");"
julia --project -e "using Pkg; Pkg.precompile()"
julia --project -e "include(\"./test/create_sys_image.jl\");"
mv MakieSys_tmp.so MakieSys${branch}.so
