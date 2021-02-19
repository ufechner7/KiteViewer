if test -f "MakieSys.so"; then
    julia -J MakieSys.so --project -e "using Revise" -i
else
    julia --project -e "using Revise" -i
fi