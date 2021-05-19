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

if ! @isdefined state
    const state = State{SimFloat, KPS3.Vec3}()
    const SEGMENTS  = 6
end

function test_initial_condition(params)
    res1 = zeros(SVector{SEGMENTS+1, KPS3.Vec3})
    res2 = deepcopy(res1)
    res = reduce(vcat, vcat(res1, res2))
    y0, yd0 = get_state_392(params[1:SEGMENTS], params[SEGMENTS+1:end])
    p = SciMLBase.NullParameters()
    residual!(res, yd0, y0, p, 0.0)
    return norm(res) # z component of force on all particles but the first
end

lower = [-20, -20, -20, -20, -20, -20.0, -20, -20, -20, -20, -20, -20]
upper = [ 20,  20,  20,  20,  20,  20.0,  20,  20,  20,  20,  20,  20]
initial_x =  [-1.4665866297620287, -3.5561543609716884, -5.328280757163652, -5.825432425624137, -4.06758438870819, 1.3365850018520555, 0.34726455461348643, 0.8708697538110506, 1.2180971705802224, 1.077432049937649, 0.20510584981238655, -1.6322406908860976]
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

