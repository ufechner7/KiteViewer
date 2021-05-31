#!/bin/bash -eu
branch=$(git rev-parse --abbrev-ref HEAD)
if test -f "MakieSys${branch}.so"; then
    mv MakieSys${branch}.so MakieSys${branch}.so.bak
fi
rm -f Manifest.toml
julia --project -e "include(\"./test/update_packages.jl\");"
julia --project -e "using Pkg; Pkg.precompile()"
julia --project -e "include(\"./test/create_sys_image.jl\");"
mv MakieSys_tmp.so MakieSys${branch}.so
julia --project -e "using Pkg; Pkg.precompile()"
julia --project -J MakieSys${branch}.so -e "push!(LOAD_PATH,joinpath(pwd(),\"src\"));using Utils, KCU_Sim, KPS3, Plot2D, RTSim"
