#!/bin/bash -eu
update=false
if [[ $# -gt 0 ]]; then
    if [[ $1 != "--update" ]]; then
        echo "Invalid parameter! Use:"
        echo "./create_sys_image.sh"
        echo "or"
        echo "./create_sys_image.sh --update"
        exit 1
    else
        update=true
    fi
fi

branch=$(git rev-parse --abbrev-ref HEAD)
if [[ $branch == "main" ]]; then
    branch=""
fi
if test -f "MakieSys${branch}.so"; then
    mv MakieSys${branch}.so MakieSys${branch}.so.bak
fi
if [[ $update == true ]]; then
    echo "Updating packages..."
    if test -f "Manifest.toml"; then
        mv Manifest.toml Manifest.toml.bak
    fi
    julia --project -e "include(\"./test/update_packages.jl\");"
else
    echo "Using default Manifest.toml ..."
    cp Manifest.toml.default Manifest.toml
fi
julia --project -e "using Pkg; Pkg.precompile()"
julia --project -e "include(\"./test/create_sys_image.jl\");"
mv MakieSys_tmp.so MakieSys${branch}.so
julia --project -e "using Pkg; Pkg.precompile()"
cd src
touch *.jl # make sure all modules get recompiled in the next step
cd ..
julia --project -J MakieSys${branch}.so -e "push!(LOAD_PATH,joinpath(pwd(),\"src\"));using Utils, KCU_Sim, KPS3, Plot2D, RTSim"
