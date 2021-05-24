using TestNLsolve

include("test_kps3.jl")
include("test_kcu_sim.jl")
run_benchmarks()
test_nlsolve()
