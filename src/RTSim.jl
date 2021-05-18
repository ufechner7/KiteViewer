using DifferentialEquations, Sundials, GLMakie, StaticArrays
using Revise, LinearAlgebra

if ! @isdefined KPS3
    includet("../src/KPS3.jl")
    using .KPS3
end

if ! @isdefined Utils
    include("../src/Utils.jl")
    using .Utils
end

# Type definitions
const SimFloat = Float64
const Vec3     = MVector{3, SimFloat}

my_state = KPS3.get_state()
clear(my_state)
y0, yd0 = KPS3.init(my_state)

tspan = (0.0, 0.01)         # time span

differential_vars =  ones(Bool, 36)
prob = DAEProblem(residual!, yd0, y0, tspan, differential_vars=differential_vars)

sol = solve(prob, IDA(), saveat=0.001, abstol=0.01, reltol=0.001)
println("state.param_cl: $(my_state.param_cl), state.param_cd: $(my_state.param_cd)")
println("state.length: $(my_state.length)")

time = sol.t
sol.retcode
# y = sol.u

# pos_z = sol[3, :]
# vel_z = sol[6, :]

# # plot the result
# f = Figure()
# ax1 = Axis(f[1, 1], yticklabelcolor = :blue, xlabel="time [s]", ylabel = "pos_z [m]")
# ax2 = Axis(f[1, 1], yticklabelcolor = :red, yaxisposition = :right, ylabel = "vel_z [m/s]")
# lines!(ax1, time, pos_z, color=:green)
# lines!(ax2, time, vel_z, color=:red)
# current_figure()