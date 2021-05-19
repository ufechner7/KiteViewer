using Test, BenchmarkTools, StaticArrays, Revise, LinearAlgebra, SciMLBase, Optim, LineSearches

if ! @isdefined KPS3
    includet("../src/KPS3.jl")
    using .KPS3
end

function get_state_392(X, Z)
    my_state = KPS3.get_state()
    KPS3.set.l_tether = 392.0
    KPS3.set.elevation = 70.0
    KPS3.set.area = 10.0
    KPS3.set.v_wind = 9.1
    KPS3.set.mass = 6.2
    KPS3.clear(my_state)
    y0, yd0 = KPS3.init(my_state; X=X, Z=Z)
    return y0, yd0
end

const SEGMENTS  = 6

function test_initial_condition(params)
    res1 = zeros(SVector{SEGMENTS+1, KPS3.Vec3})
    res2 = deepcopy(res1)
    res = reduce(vcat, vcat(res1, res2))
    y0, yd0 = get_state_392(params[1:SEGMENTS], params[SEGMENTS+1:end])
    p = SciMLBase.NullParameters()
    residual!(res, yd0, y0, p, 0.0)
    return norm(res) # z component of force on all particles but the first
end

lower = [-10, -10, -20, -20, -10, -10.0, -5, -5, -5, -5, -5, -5]
upper = [ 10,  10,  20,  20,  10,  10.0,  5,  5,  5,  5,  5,  5]
# initial_x = [-1.52505,  -3.67761,  -5.51761,  -6.08916,  -4.41371,  0.902124,  0.366393,  0.909132,  1.27537,  1.1538,  0.300657,  -1.51768]
initial_x =  zeros(12)
inner_optimizer = BFGS(linesearch=LineSearches.BackTracking(order=3)) # GradientDescent()
results = optimize(test_initial_condition, lower, upper, initial_x, Fminbox(inner_optimizer), Optim.Options(iterations=10000))
params=(Optim.minimizer(results))
println("result: $params; minimum: $(Optim.minimum(results))")
res=test_initial_condition(params)

my_state = KPS3.get_state()
println("res2: "); display(my_state.res2)
x = Float64[] 
z = Float64[]
for i in 1:length(my_state.pos)
    push!(x, my_state.pos[i][1])
    push!(z, my_state.pos[i][3])
end  
println(results)

