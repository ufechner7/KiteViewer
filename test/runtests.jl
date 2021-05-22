using TestOptim, TestNLopt

include("test_kps3.jl")
run_benchmarks()
test_optim()
test_nlopt()
