cd("..")
let
    include("../src/Importer.jl")
end
include("test_rt_sim.jl")
run_benchmarks()
# test_nlsolve()
