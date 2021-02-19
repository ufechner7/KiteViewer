cp MakieSys.so MakieSys.so.bak
julia --project  -e "include(\"./test/create_sys_image.jl\");"