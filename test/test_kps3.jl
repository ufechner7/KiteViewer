using Test, BenchmarkTools, StaticArrays, Revise, LinearAlgebra

if ! @isdefined KPS3
    includet("../src/KPS3.jl")
    using .KPS3
end

if ! @isdefined Utils
    include("../src/Utils.jl")
    using .Utils
end

if ! @isdefined state
    const state = State{SimFloat, Vec3}()
    const SEGMENTS  = se().segments
end

@testset "calc_rho             " begin
    @test isapprox(calc_rho(0.0), 1.225, atol=1e-5) 
    @test isapprox(calc_rho(100.0), 1.210756, atol=1e-5) 
end

@testset "calc_wind_factor     " begin
    @test isapprox(calc_wind_factor(6.0),   1.0, atol=1e-5) 
    @test isapprox(calc_wind_factor(10.0),  1.0757037, atol=1e-5) 
    @test isapprox(calc_wind_factor(100.0), 1.494685, atol=1e-5)
end

@testset "calc_cl              " begin
    @test isapprox(calc_cl(-5.0), 0.150002588978, atol=1e-4) 
    @test isapprox(calc_cl( 0.0), 0.200085035326, atol=1e-4) 
    @test isapprox(calc_cl(10.0), 0.574103590856, atol=1e-4)
    @test isapprox(calc_cl(20.0), 1.0, atol=1e-4)
end

@testset "test_calc_drag       " begin
    v_segment = Vec3(1.0, 2, 3)
    unit_vector = Vec3(2.0, 3.0, 4.0)
    rho = SimFloat(calc_rho(10.0))
    last_tether_drag = Vec3(0.0, 0.0, 0.0)
    v_app_perp = Vec3(0, -3.0, -4.0)
    area=se().area   
    state.v_wind_tether .= [0.1, 0.2, 0.3]
    v_app_norm = calc_drag(state, v_segment, unit_vector, rho, last_tether_drag, v_app_perp, area)
    @test v_app_norm ≈ 3.3674916481
    @test last_tether_drag ≈ [-38506.7140169,  -57266.39520463, -76026.07639235]
    @test v_app_perp ≈ [ 35.1, 52.2, 69.3]
end

@testset "test_calc_aero_forces" begin
    state.v_apparent .= Vec3(35.1, 52.2, 69.3)
    pos_kite = Vec3(30.0, 5.0, 100.0)
    v_kite = Vec3(3.0, 5.0, 2.0)
    rho = SimFloat(calc_rho(10.0))
    rel_steering = 0.1
    state.beta = 0.1
    state.psi = 0.2
    state.param_cl = 0.2
    state.param_cd = 1.0
    KPS3.calc_aero_forces(state, pos_kite, v_kite, rho, rel_steering)
    @test state.v_apparent ≈ [5.0,  -5, -2]
    @test state.kite_y ≈ [ 0.64101597,  0.73258967, -0.22893427]
    @test state.cor_steering ≈ 0.0250173783309
    @test state.steering_force ≈ [-15.88482337, -18.15408385, 5.6731512 ]
    @test state.last_force ≈ [-555.24319976, 544.82004621, 80.49946362]
end

@testset "test_calc_res        " begin
    i = 1
    pos1 = Vec3(30.0, 5.0, 100.0)
    pos2 = Vec3(30.0+10, 5.0+11, 100.0+20)
    vel1 = Vec3(3.0, 5.0, 2.0)
    vel2 = Vec3(3.0+0.1, 5.0+0.2, 2.0+0.3)
    mass = 9.0
    veld = Vec3(0.1, 0.3, 0.4)
    result = Vec3(0, 0, 0)
    state.c_spring=0.011
    state.damping = 0.01
    state.last_tether_drag = Vec3(5.0,6,7)
    state.last_force = Vec3(-1.0, -2, -3)
    state.v_app_perp = Vec3(0.1,0.22,0.33)
    state.v_wind_tether .= [0.1, 0.2, 0.3]
    # TODO make it work for length > zero
    state.length = 0.0
    KPS3.calc_res(state, pos1, pos2, vel1, vel2, mass, veld, result, i)
    @test result ≈ [0.2118964, 0.50409798, 10.59137013]
    i = SEGMENTS
    KPS3.calc_res(state, pos1, pos2, vel1, vel2, mass, veld, result, i)
    @test result ≈ [0.04174994,  0.14058806, 10.32680159]
end

@testset "test_calc_loop       " begin
    state.c_spring=0.011
    state.damping = 0.01
    state.last_tether_drag = Vec3(5.0,6,7)
    state.last_force = Vec3(-1.0, -2, -3)
    state.v_app_perp = Vec3(0.1,0.22,0.33)
    state.v_wind_tether .= [0.1, 0.2, 0.3]
    # TODO make it work for length > zero
    state.length = 0.0
    pos  = zeros(SVector{SEGMENTS+1, Vec3})
    vel  = zeros(SVector{SEGMENTS+1, Vec3})
    posd = zeros(SVector{SEGMENTS+1, Vec3})
    veld = zeros(SVector{SEGMENTS+1, Vec3})
    res1 = zeros(SVector{SEGMENTS+1, Vec3})
    res2 = zeros(SVector{SEGMENTS+1, Vec3})
    KPS3.loop(state, pos, vel, posd, veld, res1, res2)
end

@testset "test_calc_alpha      " begin
    v_app = Vec3(10,2,3)
    vec_z = normalize(Vec3(3,2,0))
    alpha = KPS3.calc_alpha(v_app, vec_z)
    @test alpha ≈ -1.091003745821884
end

@testset "test_set_cl_cd       " begin
    alpha = 10.0
    KPS3.set_cl_cd(state, alpha)
end

@testset "test_set_lod         " begin
    v_app = Vec3(10,2,3)
    vec_c = Vec3(3,2,0)
    KPS3.set_lod(state, vec_c, v_app)
end

println("\ncalc_rho:")
show(@benchmark calc_rho(height) setup=(height=1.0 + rand() * 200.0))
println("\ncalc_wind_factor:")
show(@benchmark calc_wind_factor(height) setup=(height=rand() * 200.0))
println("\ncalc_cl:")
show(@benchmark calc_cl(α) setup=(α=(rand()-0.5) * 360.0))
println("\ncalc_drag:")
show(@benchmark calc_drag(state, v_segment, unit_vector, rho, last_tether_drag, v_app_perp, 
                          area) setup=(v_segment = Vec3(1.0, 2, 3);
                          unit_vector = Vec3(2.0, 3.0, 4.0); 
                          rho = calc_rho(10.0f0); last_tether_drag = Vec3(0.0, 0.0, 0.0); 
                          v_app_perp =  Vec3(0, -3.0, -4.0); area=se().area))
println("\ncalc_aero_forces:")
show(@benchmark KPS3.calc_aero_forces(state, pos_kite, v_kite, rho, rel_steering) setup=(state.v_apparent .= Vec3(35.1,
                                      52.2, 69.3); pos_kite = Vec3(30.0, 5.0, 100.0);  
                                      v_kite = Vec3(3.0, 5.0, 2.0);  
                                      rho = SimFloat(calc_rho(10.0));  rel_steering = 0.1))
println("\ncalc_res:")
show(@benchmark KPS3.calc_res(state, pos1, pos2, vel1, vel2, mass, veld, result, i) setup=(i = 1; 
                         pos1 = Vec3(30.0, 5.0, 100.0); pos2 = Vec3(30.0+10, 5.0+11, 100.0+20); 
                         vel1 = Vec3(3.0, 5.0, 2.0); vel2 = Vec3(3.0+0.1, 5.0+0.2, 2.0+0.3); 
                         mass = 9.0; veld = Vec3(0.1, 0.3, 0.4); result = Vec3(0, 0, 0)))
println("\ncalc_loop")
show(@benchmark KPS3.loop(state, pos, vel, posd, veld, res1, res2) setup=(pos = zeros(SVector{SEGMENTS+1, Vec3}); 
                          vel  = zeros(SVector{SEGMENTS+1, Vec3}); posd  = zeros(SVector{SEGMENTS+1, Vec3}); 
                          veld  = zeros(SVector{SEGMENTS+1, Vec3}); res1  = zeros(SVector{SEGMENTS+1, Vec3}); 
                          res2  = zeros(SVector{SEGMENTS+1, Vec3}) ))
println("\nset_cl_cd")
show(@benchmark set_cl_cd(state, alpha) setup= (alpha = 10.0))
println("\ncalc_alpha")
show(@benchmark KPS3.calc_alpha(v_app, vec_z) setup=(v_app = Vec3(10,2,3); vec_z = normalize(Vec3(3,2,0))))
println("\nset_lod")
show(@benchmark KPS3.set_lod(state, vec_c, v_app) setup=(v_app = Vec3(10,2,3); vec_c = Vec3(3,2,0)))
nothing
