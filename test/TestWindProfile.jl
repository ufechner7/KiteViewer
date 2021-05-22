module TestWindProfile

using Test, BenchmarkTools, GLMakie, LinearAlgebra, Reexport

include("../src/KPS3.jl")
@reexport using .KPS3

export test_wind_profile, test_force

function init_392()
    my_state = KPS3.get_state()
    KPS3.set.l_tether = 392.0
    KPS3.set.elevation = 70.0
    KPS3.set.area = 10.0
    KPS3.set.v_wind = 9.1
    KPS3.set.mass = 6.2
    KPS3.clear(my_state)
end

function test_wind_profile(height = 10.0, profile_law=EXP)
    println("Wind factor: $(calc_wind_factor(height, profile_law)) at $(height) m height.")
end

function test_force()
    state=KPS3.get_state()
    init_392()
    KPS3.init(state)
    forces = KPS3.get_spring_forces(state, state.pos)
    winch_force=forces[1]
    println("Winch force: $(winch_force) N")
    return state
end

end