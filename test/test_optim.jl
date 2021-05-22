module TestOptim

using Test, BenchmarkTools, StaticArrays, Revise, LinearAlgebra, SciMLBase, Optim, LineSearches, GLMakie

export test_optim

include("../src/KPS3.jl")
using .KPS3

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

function test_initial_condition(params::Vector)
    my_state = KPS3.get_state()
    y0, yd0 = KPS3.init(my_state, params)
    residual!(res, yd0, y0, 0.0, 0.0)
    return norm(res) # z component of force on all particles but the first
end

function test_optim(;plot=false, prn=false)
    lower = [-10, -10, -20, -20, -10, -10.0, -5, -5, -5, -5, -5, -5]
    upper = [ 10,  10,  20,  20,  10,  10.0,  5,  5,  5,  5,  5,  5]
    initial_x =  zeros(12)
    init_392()
    inner_optimizer = BFGS(linesearch=LineSearches.BackTracking(order=3)) # GradientDescent()
    results = optimize(test_initial_condition, lower, upper, initial_x, Fminbox(inner_optimizer), Optim.Options(iterations=10000))
    params=(Optim.minimizer(results))
    println("result: $params; minimum: $(Optim.minimum(results))")
    res4=test_initial_condition(params)
    show(@test res4 < 0.3)

    my_state = KPS3.get_state()
    if prn
        println("res2: "); display(my_state.res2)
    end
    x = Float64[] 
    z = Float64[]
    for i in 1:length(my_state.pos)
        push!(x, my_state.pos[i][1])
        push!(z, my_state.pos[i][3])
    end  
    if prn println(results) end

    if plot 
        return lines(x, z)
    end
    return nothing
end

end
using .TestOptim