#!/bin/bash
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

julia_version=$(julia --version | awk '{print($3)}')
julia_major=${julia_version:0:3} 
branch=$(git rev-parse --abbrev-ref HEAD)

echo "Lauching KiteViewer..."
if test -f "MakieSys-${julia_major}-${branch}.so"; then
    julia --startup-file=no  -t 1 -J MakieSys-${julia_major}-${branch}.so --optimize=2 --project -e "push!(LOAD_PATH,joinpath(pwd(),\"src\"));include(\"./src/KiteViewerPure.jl\");main(true)"
else
    julia --startup-file=no -t auto --optimize=2 --project -e "include(\"./src/KiteViewerPure.jl\");main(true)"
fi
