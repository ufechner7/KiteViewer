using Test

using KCU_Sim: calc_alpha_depower

using RTSim

@testset "test_rt_sim" begin
    integrator=init_sim(0.05)
    @test length(integrator.u) == 36
    @test integrator.u[1] ≈ 26.95752308322001
    state=next_step(7, integrator, 0.05)
    @test state.time ≈ 0.05
    @test get_height() ≈ 368.74700144466385
end

nothing