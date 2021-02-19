#!/bin/bash
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

if test -f "~/.bashrc"; then
    source ~/.bashrc
fi

echo "Lauching KiteViewer..."
if test -f "MakieSys.so"; then
    julia --startup-file=no  -J MakieSys.so --optimize=1 --project -e "include(\"./src/KiteViewer.jl\");main(true)"
else
    julia --startup-file=no --optimize=1 --project -e "include(\"./src/KiteViewer.jl\");main(true)"
fi
