@info "Updating packages ..."
using Pkg
Pkg.resolve()
Pkg.instantiate()
Pkg.update()
Pkg.precompile()
