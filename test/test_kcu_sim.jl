using Test

using KitePodSimulator: calc_alpha_depower

@testset "test_calc_alpha_depower" begin
    rel_depower = 0.25
    alpha = calc_alpha_depower(rel_depower)
    @test 180.0 * alpha / π ≈ 2.1438208267482795
    rel_depower = 0.5
    alpha = calc_alpha_depower(rel_depower)
    @test 180.0 * alpha / π ≈ 39.56291863406212
end

nothing