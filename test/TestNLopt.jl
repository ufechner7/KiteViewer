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
    lower = SVector{2*SEGMENTS}(-10, -20, -20, -20, -30, -40.0, -10, -10, -10, -10, -10, -10)
    upper = SVector{2*SEGMENTS}( 10,  20,  20,  20,  30,  40.0,  10,  10,  10,  10,  10,  10)
    # initial_x = MVector{2*SEGMENTS}(zeros(12))
    initial_x = MVector{2*SEGMENTS}(5.3506365772036615, 9.200200773784072, 12.106325985815378, 14.638292099163197, 17.379867429065342, 21.56465630857364, -2.232627620821657, -3.77671345226395, -4.891355444812783, -5.822234551550322, -6.7917091935113945, -8.16300817107152)
    init_392()
    # working: :GD_STOGO 1803, :GD_STOGO_RAND 1403, :GN_ESCH 378, :GN_DIRECT_L 122, :GN_DIRECT_L_RAND 116, :GN_ISRES 82.8, :GN_CRS2_LM 60; not working: GN_AGS
    # in 15 min :GN_CRS2_LM: 27;
    # in  1 min :LN_SBPLX 9.96 in 15 min: 1.13
    # in  1 min :LN_BOBYQA 0.31; LN_COBYLA 25; LD_MMA 6046; not working: LD_SLSQP
    # without time limit: 0.00159 ROUNDOFF_LIMITED; took 495s, 39628692 numevals or 12.5 us per numeval
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
        show(@test minf < 0.002)
    end
    
    println("\nresult: $minx; minimum: $minf")

    my_state = KPS3.get_state()
    res = KPS3.calc_pre_tension(my_state)
    println("\npre_tension: $res")

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
