using TestNLsolve

include("test_kps3.jl")
let
    include("test_kcu_sim.jl")
end
include("test_rt_sim.jl")
run_benchmarks()
test_nlsolve()
