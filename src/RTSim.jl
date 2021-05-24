using Sundials, GLMakie, StaticArrays
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

differential_vars =  ones(Bool, 36)
solver = IDA(linear_solver=:Dense)
dt = 0.5
t_start = 0.0
t_end   = 5*dt
tspan = (t_start, t_end) 

prob = DAEProblem(residual!, yd0, y0, tspan, differential_vars=differential_vars)
integrator = init(prob, solver, abstol=0.000001, reltol=0.001)

for i in 1:5
    step!(integrator, dt, stop_at_tdt=true)
    # println(check_error(integrator))
    for (u,t) in tuples(integrator)
        # y = u[end][1:3*KPS3.SEGMENTS]
        @show u[18], t
    end
    # @time global sol = solve(prob, solver, saveat=0.025, abstol=0.000001, reltol=0.001)
    # y0  .= sol.u[end][1:3*KPS3.SEGMENTS]
    # yd0 .= sol.u[end][3*KPS3.SEGMENTS+1:end]
    # println(y[end])
end

# time = sol.t
# println(sol.retcode)
# y = sol.u
# println(length(y))

# pos_x = sol[3*5+1, :]
# pos_z = sol[3*5+3, :]
# forces = KPS3.get_spring_forces(my_state, my_state.pos)
# println(forces)
# x=[my_state.pos[i][1] for i in 1:7]
# z=[my_state.pos[i][3] for i in 1:7]
# lines(x,z)

# # plot the result
# f = Figure()
# ax1 = Axis(f[1, 1], yticklabelcolor = :blue, xlabel="time [s]", ylabel = "pos_z [m]")
# ax2 = Axis(f[1, 1], yticklabelcolor = :red, yaxisposition = :right, ylabel = "vel_z [m/s]")
# lines!(ax1, time, pos_z, color=:green)
# lines!(ax2, time, vel_z, color=:red)
# current_figure()