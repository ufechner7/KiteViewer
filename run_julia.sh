#!/bin/bash

if which jill ; then # if jill is installed
    jill switch 1.6
fi
cp -u Manifest.toml.default Manifest.toml
branch=$(git rev-parse --abbrev-ref HEAD)
if [[ $branch == "main" ]]; then
    branch=""
fi
if test -f "MakieSys${branch}.so"; then
    julia -J MakieSys${branch}.so --project -e "push!(LOAD_PATH,joinpath(pwd(),\"test\"));push!(LOAD_PATH,joinpath(pwd(),\"src\")); using Revise" -i
else
    julia --project -e "push!(LOAD_PATH,joinpath(pwd(),\"test\"));push!(LOAD_PATH,joinpath(pwd(),\"src\")); using Revise" -i
fi
