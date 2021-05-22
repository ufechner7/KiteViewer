module TestNLopt

using Test, BenchmarkTools, StaticArrays, Revise, LinearAlgebra, SciMLBase, NLopt, GLMakie

export test_nlopt

include("../src/KPS3.jl")
using .KPS3

function init_392()
    my_state = KPS3.get_state()
    KPS3.set.l_tether = 392.0
    KPS3.set.elevation = 70.7
    KPS3.set.area = 10.18
    KPS3.set.v_wind = 9.51
    KPS3.set.mass = 6.2
    KPS3.clear(my_state)
end

const SEGMENTS  = 6

res1 = zeros(SVector{SEGMENTS+1, KPS3.Vec3})
res2 = deepcopy(res1)
const res = MVector{2*(SEGMENTS+1)*3, Float64}(reduce(vcat, vcat(res1, res2)))

function test_initial_condition(params::Vector, grad::Vector)
    my_state = KPS3.get_state()
    y0, yd0 = KPS3.init(my_state, params)
    residual!(res, yd0, y0, 0.0, 0.0)
    return norm(res) # z component of force on all particles but the first
end

function test_nlopt(;plot=false, prn=false, maxtime=60.0)
    lower = SVector{2*SEGMENTS}(-10, -20, -20, -20, -30, -30.0, -10, -10, -10, -10, -10, -10)
    upper = SVector{2*SEGMENTS}( 10,  20,  20,  20,  30,  30.0,  10,  10,  10,  10,  10,  10)
    # initial_x = MVector{2*SEGMENTS}(zeros(12))
    initial_x = MVector{2*SEGMENTS}(5.617362076915606, 9.771638917941374, 13.020673644344296, 15.933607680730749, 19.09372236996475, 23.54738098020864, -2.3526927098618553, -4.0225056446785326, -5.266058932795173, -6.326514623100387, -7.423716705063102, -8.869877563202282)
    init_392()
    # working: :GD_STOGO 1803, :GD_STOGO_RAND 1403, :GN_ESCH 378, :GN_DIRECT_L 122, :GN_DIRECT_L_RAND 116, :GN_ISRES 82.8, :GN_CRS2_LM 60; not working: GN_AGS
    # in 15 min :GN_CRS2_LM: 27;
    # in  1 min :LN_SBPLX 9.96 in 15 min: 1.13
    # in  1 min :LN_BOBYQA 0.31; LN_COBYLA 25; LD_MMA 6046; not working: LD_SLSQP
    # without time limit: 0.0001699365589509266 ROUNDOFF_LIMITED; took 495s, 39628692 numevals or 12.5 us per numeval
    opt = Opt(:LN_BOBYQA, 12) 
    opt.lower_bounds = lower
    opt.upper_bounds = upper
    # opt.xtol_rel = 1e-5
    # opt.xtol_abs = 0.001
    # opt.stopval = 0.01
    opt.maxtime = maxtime
    println("\nStarted function test_nlopt... Will take $(opt.maxtime) seconds!")
    opt.min_objective = test_initial_condition
    (minf, minx, ret) = optimize(opt, initial_x)
    if maxtime >= 60.0
        show(@test minf < 0.004)
    end
    println("\nresult: $minx; minimum: $minf")

    my_state = KPS3.get_state()
    if prn println("res2: "); display(my_state.res2) end
    x = Float64[] 
    z = Float64[]
    for i in 1:length(my_state.pos)
        push!(x, my_state.pos[i][1])
        push!(z, my_state.pos[i][3])
    end
    if prn  
        println(ret)
        println("minf: $minf")
    end
    forces = KPS3.get_spring_forces(my_state, my_state.pos)
    println("\nForces in N:")
    println(forces)
    
    if plot
        lines(x, z)
    end
end

end
