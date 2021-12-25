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

julia_version=$(julia --version | awk '{print($3)}')
julia_major=${julia_version:0:3} 
branch=$(git rev-parse --abbrev-ref HEAD)
if test -f "MakieSys-${julia_major}-${branch}.so"; then
    mv MakieSys-${julia_major}-${branch}.so MakieSys-${julia_major}-${branch}.so.bak
fi

if [[ $update == true ]]; then
    echo "Updating packages..."
    if test -f "Manifest.toml"; then
        mv Manifest.toml Manifest.toml.bak
    fi
    julia --project -e "include(\"./test/update_packages.jl\");"
else
    if [[ $julia_major == "1.6" ]]; then
        cp Manifest-1.6.toml.default Manifest.toml
        echo "Using Manifest-1.6.toml.default ..."
    else
        cp Manifest-1.7.toml.default Manifest.toml
        echo "Using Manifest-1.7.toml.default ..."
    fi
fi
julia --project -e "using Pkg; Pkg.precompile()"
julia --project -e "include(\"./test/create_sys_image.jl\");"
mv MakieSys_tmp.so MakieSys-${julia_major}-${branch}.so
julia --project -e "using Pkg; Pkg.precompile()"
cd src
touch *.jl # make sure all modules get recompiled in the next step
cd ..
julia --project -J MakieSys-${julia_major}-${branch}.so -e "push!(LOAD_PATH,joinpath(pwd(),\"src\"));using KiteUtils, KCU_Sim, KPS3, Plot2D, RTSim"
