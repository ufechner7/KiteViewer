using Test, BenchmarkTools, StaticArrays, Revise, LinearAlgebra, SciMLBase, Optim, GLMakie, LineSearches

if ! @isdefined KPS3
    includet("../src/KPS3.jl")
    using .KPS3
end

if ! @isdefined Utils
    include("../src/Utils.jl")
    using .Utils
end

function set_defaults(state)
    KPS3.set.l_tether = 150.0
    KPS3.set.elevation = 60.0
    KPS3.set.area = 20.0
    KPS3.set.v_wind = 8.0
    KPS3.set.mass = 11.4
    KPS3.set.damping =  2 * 473.0
    KPS3.set.alpha = 1.0/7
    KPS3.clear(state)
end

function init_392()
    my_state = KPS3.get_state()
    KPS3.set.l_tether = 392.0
    KPS3.set.elevation = 70.0
    KPS3.set.area = 10.0
    KPS3.set.v_wind = 9.1
    KPS3.set.mass = 6.2
    KPS3.clear(my_state)
end

if ! @isdefined state
    const state = State{SimFloat, KPS3.KPS3.Vec3}()
    const SEGMENTS  = se().segments
    set_defaults(state)
end


@testset "calc_rho             " begin
    @test isapprox(calc_rho(0.0), 1.225, atol=1e-5) 
    @test isapprox(calc_rho(100.0), 1.210756, atol=1e-5) 
end

@testset "calc_wind_factor     " begin
    my_state = KPS3.get_state()
    set_defaults(my_state)
    @test isapprox(calc_wind_factor(6.0, EXP),   1.0, atol=1e-5) 
    @test isapprox(calc_wind_factor(10.0, EXP),  1.0757037, atol=1e-5) 
    @test isapprox(calc_wind_factor(100.0, EXP), 1.494685, atol=1e-5)
end

@testset "calc_cl              " begin
    @test isapprox(calc_cl(-5.0), 0.150002588978, atol=1e-4) 
    @test isapprox(calc_cl( 0.0), 0.200085035326, atol=1e-4) 
    @test isapprox(calc_cl(10.0), 0.574103590856, atol=1e-4)
    @test isapprox(calc_cl(20.0), 1.0, atol=1e-4)
end

@testset "test_calc_drag       " begin
    v_segment = KPS3.Vec3(1.0, 2, 3)
    unit_vector = KPS3.Vec3(2.0, 3.0, 4.0)
    rho = SimFloat(calc_rho(10.0))
    last_tether_drag = KPS3.Vec3(0.0, 0.0, 0.0)
    v_app_perp = KPS3.Vec3(0, -3.0, -4.0)
    area = 20.0   
    state.v_wind_tether .= [0.1, 0.2, 0.3]
    v_app_norm = calc_drag(state, v_segment, unit_vector, rho, last_tether_drag, v_app_perp, area)
    @test v_app_norm ≈ 3.3674916481
    @test last_tether_drag ≈ [-38506.7140169,  -57266.39520463, -76026.07639235]
    @test v_app_perp ≈ [ 35.1, 52.2, 69.3]
end

@testset "test_calc_aero_forces" begin
    set_defaults(state)
    state.v_apparent .= KPS3.Vec3(35.1, 52.2, 69.3)
    pos_kite = KPS3.Vec3(30.0, 5.0, 100.0)
    v_kite = KPS3.Vec3(3.0, 5.0, 2.0)
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
    set_defaults(state)
    KPS3.clear(state)
    i = 2
    pos1 = KPS3.Vec3(30.0, 5.0, 100.0)
    pos2 = KPS3.Vec3(30.0+10, 5.0+11, 100.0+20)
    vel1 = KPS3.Vec3(3.0, 5.0, 2.0)
    vel2 = KPS3.Vec3(3.0+0.1, 5.0+0.2, 2.0+0.3)
    mass = 9.0
    veld = KPS3.Vec3(0.1, 0.3, 0.4)
    result = KPS3.Vec3(0, 0, 0)
    state.c_spring = 0.011
    state.damping = 0.01
    state.last_tether_drag = KPS3.Vec3(5.0,6,7)
    state.last_force = KPS3.Vec3(-1.0, -2, -3)
    state.v_app_perp = KPS3.Vec3(0.1,0.22,0.33)
    state.v_wind_tether .= [0.1, 0.2, 0.3]
    state.length = 10.0
    KPS3.calc_res(state, pos1, pos2, vel1, vel2, mass, veld, result, i)
    @test_broken result ≈ [  0.20699179,   0.49870291,  10.58156092]
    i = SEGMENTS+1
    KPS3.calc_res(state, pos1, pos2, vel1, vel2, mass, veld, result, i)
    @test_broken result ≈ [0.04174994,  0.14058806, 10.32680159]
end

@testset "test_calc_loop       " begin
    KPS3.clear(state)
    state.last_tether_drag = KPS3.Vec3(5.0,6,7)
    state.last_force = KPS3.Vec3(-1.0, -2, -3)
    state.v_app_perp = KPS3.Vec3(0.1,0.22,0.33)
    state.v_wind_tether .= [0.1, 0.2, 0.3]
    state.length = 10.0
    state.c_spring = KPS3.set.c_spring / state.length
    state.damping  = KPS3.set.damping / state.length
    pos  = zeros(SVector{SEGMENTS+1, KPS3.Vec3})
    for i in 1:SEGMENTS+1
        pos[i][3] = 5.0 * (i-1)
    end
    vel  = zeros(SVector{SEGMENTS+1, KPS3.Vec3})
    posd = zeros(SVector{SEGMENTS+1, KPS3.Vec3})
    veld = zeros(SVector{SEGMENTS+1, KPS3.Vec3})
    res1 = zeros(SVector{SEGMENTS+1, KPS3.Vec3})
    res2 = zeros(SVector{SEGMENTS+1, KPS3.Vec3})
    @test state.c_spring ≈ 61460.0
    @test state.damping  ≈    94.6
    KPS3.loop(state, pos, vel, posd, veld, res1, res2)
    @test sum(res1) ≈ [0.0, 0.0, 0.0]
    @test_broken isapprox(res2[7], [5.03576566e-02, 1.00715313e-01, 7.81683430e+02], rtol=1e-4) 
    @test_broken isapprox(res2[6], [9.13190455e-03, 1.82638091e-02, 9.81000000e+00], rtol=1e-4) 
    @test_broken isapprox(res2[5], [2.38000593e-03, 4.76001187e-03, 9.81000000e+00], rtol=1e-4) 
    @test_broken isapprox(res2[2], [2.38418505e-03, 4.76837010e-03, 9.81000000e+00], rtol=1e-4)
    @test isapprox(res2[1], [0.0,0.0,0.0], rtol=1e-4)
end

@testset "test_calc_alpha      " begin
    v_app = KPS3.Vec3(10,2,3)
    vec_z = normalize(KPS3.Vec3(3,2,0))
    alpha = KPS3.calc_alpha(v_app, vec_z)
    @test alpha ≈ -1.091003745821884
end

@testset "test_set_cl_cd       " begin
    alpha = 10.0
    KPS3.set_cl_cd(state, alpha)
end

@testset "test_calc_set_cl_cd  " begin
    v_app = KPS3.Vec3(10,2,3)
    vec_c = KPS3.Vec3(3,2,0)
    KPS3.calc_set_cl_cd(state, vec_c, v_app)
end

@testset "test_clear           " begin
    KPS3.clear(state)
end

# Inputs:
# State vector state_y   = pos1, pos2, ..., posn, vel1, vel2, ..., veln
# Derivative   der_yd    = vel1, vel2, ..., veln, acc1, acc2, ..., accn
# Output:
# Residual     res = res1, res2 = pos1,  ..., vel1, ...
@testset "test_residual!       " begin
    res1 = zeros(SVector{SEGMENTS, KPS3.Vec3})
    res2 = deepcopy(res1)
    res = reduce(vcat, vcat(res1, res2))
    pos = deepcopy(res1)
    pos[1] .= [1.0,2,3]
    vel = deepcopy(res1) 
    y = reduce(vcat, vcat(pos, vel))
    der_pos = deepcopy(res1)
    der_vel = deepcopy(res1)
    yd = reduce(vcat, vcat(der_pos, der_vel))
    p = SciMLBase.NullParameters()
    t = 0.0
    clear(state)
    residual!(res, yd, y, p, t)
end

@testset "test_set_v_reel_out  " begin
    v_reel_out = 1.1
    t_0 = 5.5
    set_v_reel_out(state, v_reel_out, t_0)
    @test state.v_reel_out ≈ 1.1
    @test state.t_0 ≈ 5.5
    clear(state)
end

@testset "test_set_depower_steering" begin
    depower  = 0.25
    steering = 0.0
    set_depower_steering(state, depower, steering)
end

@testset "test_init            " begin
    my_state = deepcopy(state)
    y0, yd0 = KPS3.init(my_state)
    @test length(y0)  == (SEGMENTS) * 6
    @test length(yd0) == (SEGMENTS) * 6
    @test sum(y0)  ≈ 761.6911185671187
    @test sum(yd0) ≈ 3.6e-5
    @test isapprox(my_state.param_cl, 0.574103590856, atol=1e-4)
    @test isapprox(my_state.param_cd, 0.125342896308, atol=1e-4)
end

res1 = zeros(SVector{SEGMENTS+1, KPS3.KPS3.Vec3})
res2 = deepcopy(res1)
if ! @isdefined res3
    const res3 = reduce(vcat, vcat(res1, res2))
end

function test_initial_condition(params::Vector)
    my_state = KPS3.get_state()
    y0, yd0 = KPS3.init(my_state, params)
    residual!(res3, yd0, y0, 0.0, 0.0)
    return norm(res3) # z component of force on all particles but the first
end

res = nothing
x= nothing
z= nothing
@testset "test_initial_residual" begin
    global res, x, z
    init_392()
    initial_x =  [-1.52505,  -3.67761,  -5.51761,  -6.08916,  -4.41371,  0.902124,  0.366393,  0.909132,  1.27537,  1.1538,  0.300657,  -1.51768]
    res=test_initial_condition(initial_x)

    my_state = KPS3.get_state()
    KPS3.set.l_tether = 392.0
    KPS3.set.elevation = 70.0
    KPS3.set.area = 10.0
    KPS3.set.v_wind = 9.1
    KPS3.set.mass = 6.2
    KPS3.clear(my_state)
    # println("state.param_cl: $(my_state.param_cl), state.param_cd: $(my_state.param_cd)")
    # println("res2: "); display(my_state.res2)
    # println("pos: "); display(my_state.pos)
    x = Float64[] 
    z = Float64[]
    for i in 1:length(my_state.pos)
        push!(x, my_state.pos[i][1])
        push!(z, my_state.pos[i][3])
    end  
    # println(norm(res))

    #=
    @test my_state.length ≈ 65.36666666666667
    @test my_state.c_spring ≈ 9402.345741968382
    @test my_state.damping  ≈  14.472208057113717
    @test isapprox(my_state.param_cl, 1.0, atol=1e-4)
    @test isapprox(my_state.param_cd, 0.2, atol=1e-4) # [-275.31680793466865, -3.5309114469539753e-5, -873.0000830018812]
 
    @test sum(my_state.res1) ≈ [0.0, 1.0e-6, 0.0]
    @test my_state.res2[1]   ≈ [1.00000000e-06,  1.00000000e-06,  1.00000000e-06] =#

    # @test isapprox(my_state.res2[2], [8.83559075e+00, -4.72588546e-07, -5.10109289e+00], rtol=3e-2)
    # @test isapprox(my_state.res2[3], [8.81318565e+00, -4.68864292e-07, -5.08829453e+00], rtol=1e-3)
    # @test isapprox(my_state.res2[7], [1.49735632e+01,  2.71870215e-06,  4.51115984e+01], rtol=1e-3)
    # println("res2: "); display(my_state.res2)
    # println("lift force: $(norm(my_state.lift_force)) N")
end
# lines(x, z)

function run_benchmarks()
    println("\ncalc_rho:")
    show(@benchmark calc_rho(height) setup=(height=1.0 + rand() * 200.0))
    println("\ncalc_wind_factor:")
    show(@benchmark calc_wind_factor(height) setup=(height=rand() * 200.0))
    println("\ncalc_cl:")
    show(@benchmark calc_cl(α) setup=(α=(rand()-0.5) * 360.0))
    println("\ncalc_drag:")
    show(@benchmark calc_drag(state, v_segment, unit_vector, rho, last_tether_drag, v_app_perp, 
                            area) setup=(v_segment = KPS3.Vec3(1.0, 2, 3);
                            unit_vector = KPS3.Vec3(2.0, 3.0, 4.0); 
                            rho = calc_rho(10.0f0); last_tether_drag = KPS3.Vec3(0.0, 0.0, 0.0); 
                            v_app_perp =  KPS3.Vec3(0, -3.0, -4.0); area=se().area))
    println("\ncalc_aero_forces:")
    show(@benchmark KPS3.calc_aero_forces(state, pos_kite, v_kite, rho, rel_steering) setup=(state.v_apparent .= KPS3.Vec3(35.1,
                                        52.2, 69.3); pos_kite = KPS3.Vec3(30.0, 5.0, 100.0);  
                                        v_kite = KPS3.Vec3(3.0, 5.0, 2.0);  
                                        rho = SimFloat(calc_rho(10.0));  rel_steering = 0.1))
    println("\ncalc_res:")
    show(@benchmark KPS3.calc_res(state, pos1, pos2, vel1, vel2, mass, veld, result, i) setup=(i = 1; 
                            pos1 = KPS3.Vec3(30.0, 5.0, 100.0); pos2 = KPS3.Vec3(30.0+10, 5.0+11, 100.0+20); 
                            vel1 = KPS3.Vec3(3.0, 5.0, 2.0); vel2 = KPS3.Vec3(3.0+0.1, 5.0+0.2, 2.0+0.3); 
                            mass = 9.0; veld = KPS3.Vec3(0.1, 0.3, 0.4); result = KPS3.Vec3(0, 0, 0)))
    println("\ncalc_loop")
    show(@benchmark KPS3.loop(state, pos, vel, posd, veld, res1, res2) setup=(pos = zeros(SVector{SEGMENTS+1, KPS3.Vec3}); 
                            vel  = zeros(SVector{SEGMENTS+1, KPS3.Vec3}); posd  = zeros(SVector{SEGMENTS+1, KPS3.Vec3}); 
                            veld  = zeros(SVector{SEGMENTS+1, KPS3.Vec3}); res1  = zeros(SVector{SEGMENTS+1, KPS3.Vec3}); 
                            res2  = zeros(SVector{SEGMENTS+1, KPS3.Vec3}) ))
    println("\nset_cl_cd")
    show(@benchmark KPS3.set_cl_cd(state, alpha) setup= (alpha = 10.0))
    println("\ncalc_alpha")
    show(@benchmark KPS3.calc_alpha(v_app, vec_z) setup=(v_app = KPS3.Vec3(10,2,3); vec_z = normalize(KPS3.Vec3(3,2,0))))
    println("\ncalc_set_cl_cd")
    show(@benchmark KPS3.calc_set_cl_cd(state, vec_c, v_app) setup=(v_app = KPS3.Vec3(10,2,3); vec_c = KPS3.Vec3(3,2,0)))
    println("\nresidual!")
    show(@benchmark residual!(res, yd, y, p, t) setup = (res1 = zeros(SVector{SEGMENTS, KPS3.Vec3}); res2 = deepcopy(res1); 
                                                            res = reduce(vcat, vcat(res1, res2)); pos = deepcopy(res1);
                                                            pos[1] .= [1.0,2,3]; vel = deepcopy(res1); y = reduce(vcat, vcat(pos, vel));
                                                            der_pos = deepcopy(res1); der_vel = deepcopy(res1); yd = reduce(vcat, vcat(der_pos, der_vel));
                                                            p = SciMLBase.NullParameters(); t = 0.0))
    println("\ntest_initial_condition")
    show(@benchmark res=test_initial_condition(initial_x) setup = (initial_x = (zeros(12))))
    println()
end