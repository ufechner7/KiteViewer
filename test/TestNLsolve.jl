module TestNLsolve

using Test, BenchmarkTools, StaticArrays, Revise, LinearAlgebra, SciMLBase, NLsolve, GLMakie, Reexport, LineSearches

export test_nlsolve

include("../src/KPS3.jl")
@reexport using .KPS3

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

res1 = zeros(SVector{SEGMENTS, KPS3.Vec3})
res2 = deepcopy(res1)
const res = MVector{2*(SEGMENTS)*3, Float64}(reduce(vcat, vcat(res1, res2)))

function test_initial_condition(F, x::Vector)
    my_state = KPS3.get_state()
    y0, yd0 = KPS3.init(my_state, x)
    residual!(res, yd0, y0, 0.0, 0.0)
    for i in 1:SEGMENTS
        F[i] = res[1+3*(i-1)+18]
        F[i+SEGMENTS] = res[3+3*(i-1)+18]
    end
    return nothing 
end

function test_final_condition(params::Vector)
    my_state = KPS3.get_state()
    y0, yd0 = KPS3.init(my_state, params)
    residual!(res, yd0, y0, 0.0, 0.0)
    return norm(res) # z component of force on all particles but the first
end

function test_nlsolve(;plot=false, prn=false)
    initial_x =  zeros(12)
    init_392()
    my_state = KPS3.get_state()
    println("\nStarted function test_nlsolve...")
    @time results = nlsolve(test_initial_condition, initial_x)

    println("\nresult: $results")
    params=results.zero
    res4=test_final_condition(params)
    println("res: $res4")
    show(@test res4 < 0.001)

    pre_tension = KPS3.calc_pre_tension(my_state)
    println("\npre_tension: $pre_tension")
    if prn
        println("\nres2: "); display(my_state.res2)
    end
    x = Float64[] 
    z = Float64[]
    for i in 1:length(my_state.pos)
        push!(x, my_state.pos[i][1])
        push!(z, my_state.pos[i][3])
    end  
    if prn println(results) end

    forces = KPS3.get_spring_forces(my_state, my_state.pos)
    println("\nForces in N:")
    println(forces)

    if plot 
        lines(x,z)
        scatter!(x, z, marker='+', markersize=15.0)
        fig = current_figure()
        # save("plot.png, fig")
        return fig
    end
end

end
