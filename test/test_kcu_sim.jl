using Test, BenchmarkTools, StaticArrays, Revise, LinearAlgebra, SciMLBase

if ! @isdefined KCU_Sim
    includet("../src/KCU_Sim.jl")
    using .KCU_Sim
end

@testset "test_calc_alpha_depower" begin
    rel_depower = 0.0
    alpha = calc_alpha_depower(rel_depower)
    println(180.0 * alpha / π)
end

nothing