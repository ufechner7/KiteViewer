using DifferentialEquations, Sundials, GLMakie, StaticArrays
using Revise

if ! @isdefined KPS3
    includet("../src/KPS3.jl")
    using .KPS3
end

my_state = KPS3.get_state()
clear(my_state)
y0, yd0 = KPS3.init(my_state)

tspan = (0.0, 0.04)         # time span; fails when changed to (0.0, 0.064); works with 0.063

differential_vars =  ones(Bool, 36)
prob = DAEProblem(residual!, yd0, y0, tspan, differential_vars=differential_vars)
solver = IDA(linear_solver=:Dense, max_order=3, max_convergence_failures=10, max_nonlinear_iters=3, init_all=false) # :BCG :GMRES :Dense :TFQMR :LapackDense

@time sol = solve(prob, solver, saveat=0.001, abstol=0.0000001, reltol=0.001) # inith = 0.002, maxord = 3, abstol=0.0000001

time = sol.t
println(sol.retcode)
y = sol.u
println(length(y))

pos_x = sol[3*5+1, :]
pos_z = sol[3*5+3, :]
nothing

# # plot the result
# f = Figure()
# ax1 = Axis(f[1, 1], yticklabelcolor = :blue, xlabel="time [s]", ylabel = "pos_z [m]")
# ax2 = Axis(f[1, 1], yticklabelcolor = :red, yaxisposition = :right, ylabel = "vel_z [m/s]")
# lines!(ax1, time, pos_z, color=:green)
# lines!(ax2, time, vel_z, color=:red)
# current_figure()