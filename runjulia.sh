#!/bin/bash
branch=$(git rev-parse --abbrev-ref HEAD)
if test -f "MakieSys${branch}.so"; then
    julia -J MakieSys${branch}.so --project -e "push!(LOAD_PATH,joinpath(pwd(),\"test\")); using Revise" -i
else
    julia --project -e "using Revise" -i
fi
