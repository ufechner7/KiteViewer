#!/bin/bash
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

if test -f "~/.bashrc"; then
    source ~/.bashrc
fi

echo "Lauching KiteViewer..."
julia --optimize=1 --project -e "include(\"./src/KiteViewer.jl\");main(true)"