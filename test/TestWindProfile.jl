module TestWindProfile

using Test, BenchmarkTools, GLMakie

include("../src/KPS3.jl")
using .KPS3

export test_wind_profile, test_force, ProfileLaw, EXP, LOG, EXPLOG

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
    KPS3.init(state, output=true)
end

end