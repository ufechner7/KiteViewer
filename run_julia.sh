#!/bin/bash
jill switch 1.6
branch=$(git rev-parse --abbrev-ref HEAD)
if test -f "MakieSys${branch}.so"; then
    julia -J MakieSys${branch}.so --project -e "push!(LOAD_PATH,joinpath(pwd(),\"test\"));push!(LOAD_PATH,joinpath(pwd(),\"src\")); using Revise" -i
else
    julia --project -e "push!(LOAD_PATH,joinpath(pwd(),\"test\"));push!(LOAD_PATH,joinpath(pwd(),\"src\")); using Revise" -i
fi