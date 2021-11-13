#!/bin/bash
RED='\033[1;31m'
NC='\033[0m' # No Color

function error_handler()
{
    printf "${RED}Error loading key packages!${NC}\n"
    echo "Try to execute the commands:"
    echo "    git checkout Project.toml"
    echo "    ./create_sys_image.sh"
    echo "first."
}

trap error_handler ERR

branch=$(git rev-parse --abbrev-ref HEAD)
if [[ $branch == "main" ]]; then
    branch=""
fi
if test -f "MakieSys${branch}.so"; then
    julia -J MakieSys${branch}.so --project -e "using Revise" -i
else
    julia --project -e "using Revise" -i
fi
