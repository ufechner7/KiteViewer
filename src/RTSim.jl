using DifferentialEquations, Sundials, GLMakie, StaticArrays
using Revise

if ! @isdefined KPS3
    includet("../src/KPS3.jl")
    using .KPS3
end

my_state = KPS3.get_state()
clear(my_state)
y0, yd0 = KPS3.find_steady_state(my_state)

forces = KPS3.get_spring_forces(my_state, my_state.pos)
println(forces)

tspan = (0.0, 40)         # time span

differential_vars =  ones(Bool, 36)
prob = DAEProblem(residual!, yd0, y0, tspan, differential_vars=differential_vars)
solver = IDA(linear_solver=:Dense, max_order=4, max_convergence_failures=10, max_nonlinear_iters=5, init_all=false) # :BCG :GMRES :Dense :TFQMR :LapackDense

@time sol = solve(prob, solver, maxord = 5, saveat=0.025, abstol=0.000001, reltol=0.001) # inith = 0.002, maxord = 3, abstol=0.0000001

time = sol.t
println(sol.retcode)
y = sol.u
println(length(y))

pos_x = sol[3*5+1, :]
pos_z = sol[3*5+3, :]
forces = KPS3.get_spring_forces(my_state, my_state.pos)
println(forces)
x=[my_state.pos[i][1] for i in 1:7]
z=[my_state.pos[i][3] for i in 1:7]
lines(x,z)

# # plot the result
# f = Figure()
# ax1 = Axis(f[1, 1], yticklabelcolor = :blue, xlabel="time [s]", ylabel = "pos_z [m]")
# ax2 = Axis(f[1, 1], yticklabelcolor = :red, yaxisposition = :right, ylabel = "vel_z [m/s]")
# lines!(ax1, time, pos_z, color=:green)
# lines!(ax2, time, vel_z, color=:red)
# current_figure()