module TestNLsolve

using Test, BenchmarkTools, StaticArrays, Revise, LinearAlgebra, SciMLBase, NLsolve, GLMakie
using KiteModels, KitePodSimulator, KiteUtils

export test_nlsolve, test_nlsolve2

const SEGMENTS = se().segments
if ! @isdefined kcu
    const kcu = KCU()
    const kps = KPS3(kcu)
end

function init_392()
    kps.set.l_tether = 392.0
    kps.set.elevation = 70.7
    kps.set.area = 10.18
    kps.set.v_wind = 9.51
    kps.set.mass = 6.2
    KiteModels.clear(kps)
end

const SEGMENTS  = 6
const res = zeros(MVector{2*(SEGMENTS)*3, Float64})

function test_initial_condition(F, x::Vector)
    y0, yd0 = KiteModels.init(kps, x)
    residual!(res, yd0, y0, 0.0, 0.0)
    for i in 1:SEGMENTS
        F[i] = res[1+3*(i-1)+18]
        F[i+SEGMENTS] = res[3+3*(i-1)+18]
    end
    return nothing 
end

function test_final_condition(params::Vector)
    y0, yd0 = KiteModels.init(kps, params)
    println(y0, yd0)
    residual!(res, yd0, y0, kps, 0.0)
    return norm(res) # z component of force on all particles but the first
end

function test_nlsolve(;plot=false, prn=false)
    initial_x =  zeros(12)
    init_392()
    println("\nStarted function test_nlsolve...")
    @time results = nlsolve(test_initial_condition, initial_x)

    # println("\nresult: $results")
    # params=results.zero
    # res4=test_final_condition(params)
    # println("res: $res4")
    # show(@test res4 < 0.001)

    # pre_tension = KiteModels.calc_pre_tension(kps)
    # println("\npre_tension: $pre_tension")
    # if prn
    #     println("\nres2: "); display(kps.res2)
    # end
    # x = Float64[] 
    # z = Float64[]
    # for i in 1:length(kps.pos)
    #     push!(x, kps.pos[i][1])
    #     push!(z, kps.pos[i][3])
    # end  
    # if prn println(results) end

    # forces = KiteModels.get_spring_forces(kps, kps.pos)
    # println("\nForces in N:")
    # println(forces)

    # if plot 
    #     lines(x,z)
    #     scatter!(x, z, marker='+', markersize=15.0)
    #     fig = current_figure()
    #     # save("plot.png, fig")
    #     return fig
    # end
end

function test_nlsolve2(;plot=false, prn=false)
    init_392()

    KiteModels.find_steady_state(kps)

    pre_tension = KiteModels.calc_pre_tension(kps)
    println("\npre_tension: $pre_tension")
    if prn
        println("\nres2: "); display(kps.res2)
    end
    x = Float64[] 
    z = Float64[]
    for i in 1:length(kps.pos)
        push!(x, kps.pos[i][1])
        push!(z, kps.pos[i][3])
    end  
    if prn println(results) end

    forces = KiteModels.get_spring_forces(kps, kps.pos)
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
