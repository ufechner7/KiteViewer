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
    step!(integrator, dt, true)
    for (u,t) in tuples(integrator)
        @show u[18], t
    end
end
