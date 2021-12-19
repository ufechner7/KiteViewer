#!/bin/bash
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

if which jill ; then
    jill switch 1.6
fi

if test -f "~/.bashrc"; then
    source ~/.bashrc
fi
branch=$(git rev-parse --abbrev-ref HEAD)

echo "Lauching KiteViewer..."
if test -f "MakieSys${branch}.so"; then
    julia --startup-file=no  -t auto -J MakieSys${branch}.so --optimize=1 --project -e "push!(LOAD_PATH,joinpath(pwd(),\"src\"));include(\"./src/KiteViewer.jl\");main(true)"
else
    julia --startup-file=no -t auto --optimize=2 --project -e "include(\"./src/KiteViewer.jl\");main(true)"
fi
