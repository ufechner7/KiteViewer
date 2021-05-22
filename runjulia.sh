#!/bin/bash
branch=$(git rev-parse --abbrev-ref HEAD)
if [[ $branch == "main" ]]; then
    branch=""
fi
if test -f "MakieSys${branch}.so"; then
    julia -J MakieSys${branch}.so --project -e "using Revise" -i
else
    julia --project -e "using Revise" -i
fi
