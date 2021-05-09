using Test

if ! @isdefined KPS3
    include("../src/KPS3.jl")
    using .KPS3
end

state = State(zeros(3), zeros(3), zeros(3), zeros(3), 0.0, 0.0)

@testset "test_calc_drag" begin
    init()
    v_segment = Vec3(1.0, 2, 3)
    unit_vector = Vec3(2.0, 3.0, 4.0)
    rho = MyFloat(calc_rho(10.0))
    last_tether_drag = Vec3(0.0, 0.0, 0.0)
    v_app_perp = Vec3(0, -3.0, -4.0)
    area=AREA    
    state.v_wind_tether .= [0.1, 0.2, 0.3]
    v_app_norm = calc_drag(state, v_segment, unit_vector, rho, last_tether_drag, v_app_perp, area)
    @test v_app_norm ≈ 3.3674916481
    @test last_tether_drag ≈ [-38506.7140169,  -57266.39520463, -76026.07639235]
    @test v_app_perp ≈ [ 35.1, 52.2, 69.3]
end

nothing
