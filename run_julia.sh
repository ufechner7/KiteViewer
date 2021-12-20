#!/bin/bash

julia_version=$(julia --version | awk '{print($3)}')
julia_major=${julia_version:0:3} 
# cp -u Manifest.toml.default Manifest.toml
branch=$(git rev-parse --abbrev-ref HEAD)
if [[ $branch == "main" ]]; then
    branch=""
fi
if test -f "MakieSys-${julia_major}-${branch}.so"; then
    julia -J  MakieSys-${julia_major}-${branch}.so --project -e "push!(LOAD_PATH,joinpath(pwd(),\"test\"));push!(LOAD_PATH,joinpath(pwd(),\"src\")); using Revise" -i
else
    julia --project -e "push!(LOAD_PATH,joinpath(pwd(),\"test\"));push!(LOAD_PATH,joinpath(pwd(),\"src\")); using Revise" -i
fi
