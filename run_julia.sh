#!/bin/bash

julia_version=$(julia --version | awk '{print($3)}')
julia_major=${julia_version:0:3} 
branch=$(git rev-parse --abbrev-ref HEAD)
# cp -u Manifest-${julia_major}.toml.default Manifest.toml
if test -f "MakieSys-${julia_major}-${branch}.so"; then
    julia -J  MakieSys-${julia_major}-${branch}.so -t 1 --optimize=2 --project -e "push!(LOAD_PATH,joinpath(pwd(),\"test\"));push!(LOAD_PATH,joinpath(pwd(),\"src\")); using Revise" -i
else
    julia --project -e "push!(LOAD_PATH,joinpath(pwd(),\"test\"));push!(LOAD_PATH,joinpath(pwd(),\"src\")); using Revise" -i
fi
