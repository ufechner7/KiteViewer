using Test, BenchmarkTools, StaticArrays, Revise, LinearAlgebra, SciMLBase, NLopt, GLMakie

if ! @isdefined KPS3
    includet("../src/KPS3.jl")
    using .KPS3
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

lower = SVector{2*SEGMENTS}(-10, -10, -20, -20, -10, -10.0, -5, -5, -5, -5, -5, -5)
upper = SVector{2*SEGMENTS}( 10,  10,  20,  20,  10,  10.0,  5,  5,  5,  5,  5,  5)
initial_x = MVector{2*SEGMENTS}(zeros(12))
# initial_x = [-1.5249315586385417, -3.677357678429133, -5.517193630804955, -6.088578528215787, -4.41292866775792, 0.9031095636714606, 0.36635378638566213, 0.9090515219653894, 1.275247708663531, 1.153628000233964, 0.3004452881238335, -1.5179358797834548]
init_392()
# working: :GD_STOGO 1803, :GD_STOGO_RAND 1403, :GN_ESCH 378, :GN_DIRECT_L 122, :GN_DIRECT_L_RAND 116, :GN_ISRES 82.8, :GN_CRS2_LM 60; not working: GN_AGS
# in 15 min: GN_CRS2_LM: 27; LN_BOBYQA 0.000189
# in  1 min :LN_SBPLX 9.96 in 15 min: 1.13
# in 1 min :LN_BOBYQA 0.31; LN_COBYLA 25; LD_MMA 6046; not working: LD_SLSQP
# without time limit: 0.00016056070408139176 ROUNDOFF_LIMITED; took 533s, 39628692 numevals or 18 us per numeval
opt = Opt(:LN_BOBYQA, 12) 
opt.lower_bounds = lower
opt.upper_bounds = upper
# opt.xtol_rel = 1e-5
# opt.xtol_abs = 0.001
# opt.stopval = 10.0
# opt.maxtime = 60.0
opt.min_objective = test_initial_condition
(minf, minx, ret) = optimize(opt, initial_x)

my_state = KPS3.get_state()
println("res2: "); display(my_state.res2)
x = Float64[] 
z = Float64[]
for i in 1:length(my_state.pos)
    push!(x, my_state.pos[i][1])
    push!(z, my_state.pos[i][3])
end  
println(ret)
println("minf: $minf")

lines(x, z)