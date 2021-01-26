echo "Lauching KiteViewer..."
julia6 --optimize=1 --project -e "include(\"./src/KiteViewer.jl\");main(true)"
